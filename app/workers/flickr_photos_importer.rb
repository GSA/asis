# frozen_string_literal: true

class FlickrPhotosImporter
  include Sidekiq::Worker
  sidekiq_options unique: true

  MAX_PHOTOS_PER_REQUEST = 500
  DAYS_BACK_TO_CHECK_FOR_UPDATES = 30
  EXTRA_FIELDS = 'description, date_upload, date_taken, owner_name, tags, views, url_q, url_o'
  OPTIONS = { per_page: MAX_PHOTOS_PER_REQUEST, extras: EXTRA_FIELDS }.freeze

  def perform(id, profile_type, days_ago = nil)
    page = 1
    pages = 1
    min_ts = days_ago.present? ? days_ago.days.ago.to_i : 0
    oldest_retrieved_ts = Time.now.to_i
    while page <= pages && oldest_retrieved_ts >= min_ts
      photos = get_photos(id, profile_type, OPTIONS.merge(page: page))
      return if photos.nil?
      Rails.logger.info("Storing #{photos.count} photos from page #{page} of #{pages} for Flickr #{profile_type} profile #{id}")
      group_id = (profile_type == 'group' ? id : nil)
      stored_photos = store_photos(photos, group_id)
      stored_photos.each { |photo| AlbumDetector.detect_albums!(photo) }
      pages = photos.pages
      page += 1
      oldest_retrieved_ts = last_uploaded_ts(photos)
    end
  end

  def self.refresh
    FlickrProfile.find_each do |flickr_profile|
      FlickrPhotosImporter.perform_async(flickr_profile.id, flickr_profile.profile_type, DAYS_BACK_TO_CHECK_FOR_UPDATES)
    end
  end

  private

  def get_photos(id, profile_type, options)
    method = "get_#{profile_type}_photos"
    send(method, id, options)
  rescue StandardError => e
    Rails.logger.warn("Trouble fetching Flickr photos for id: #{id}, profile_type: #{profile_type}, options: #{options}: #{e}")
    nil
  end

  def get_user_photos(id, options)
    FlickRaw::Flickr.new.people.getPublicPhotos(options.merge(user_id: id))
  end

  def get_group_photos(id, options)
    FlickRaw::Flickr.new.groups.pools.getPhotos(options.merge(group_id: id))
  end

  def store_photos(flickr_photo_structures, group_id)
    flickr_photo_structures.collect do |flickr_photo_structure|
      store_photo(flickr_photo_structure, group_id)
    end.compact.select(&:persisted?)
  end

  def store_photo(flickr_photo_structure, group_id)
    attributes = get_attributes(flickr_photo_structure, group_id)
    FlickrPhoto.create(attributes, op_type: 'create')
  rescue Elasticsearch::Transport::Transport::Errors::Conflict
    script = {
      source: 'ctx._source.popularity = params.new_popularity ;',
      lang: 'painless',
      params: { new_popularity: flickr_photo_structure.views }
    }
    if group_id.present?
      script[:params][:new_group] = group_id
      script[:source] += <<~SOURCE.squish
        ctx._source.groups.add(params.new_group) ;
        ctx._source.groups = ctx._source.groups.stream().distinct().collect(Collectors.toList())
      SOURCE
    end
    FlickrPhoto.gateway.update(flickr_photo_structure.id, script: script)
    nil
  rescue StandardError => e
    Rails.logger.warn("Trouble storing Flickr photo #{flickr_photo_structure.inspect}: #{e}")
    nil
  end

  def get_attributes(photo, group_id)
    tags = photo.tags.try(:split) || []
    groups = group_id.present? ? [group_id] : []
    { id: photo.id, owner: photo.owner, tags: strip_irrelevant_tags(tags), groups: groups,
      title: photo.title.squish, description: photo.description.squish, taken_at: normalize_date(photo.datetaken),
      popularity: photo.views, url: flickr_url(photo.owner, photo.id), thumbnail_url: photo.url_q }
  end

  def flickr_url(owner, flickr_id)
    "http://www.flickr.com/photos/#{owner}/#{flickr_id}/"
  end

  def last_uploaded_ts(photos)
    photos.to_a.last.dateupload.to_i
  rescue StandardError => e
    Rails.logger.warn("Trouble getting oldest upload date from photo #{photos.to_a.last}: #{e}")
    Time.now.to_i
  end

  def strip_irrelevant_tags(tags)
    tags.reject { |tag| tag.include?(':') }
  end

  def normalize_date(datetaken)
    datetaken.gsub('-00', '-01')
  end
end
