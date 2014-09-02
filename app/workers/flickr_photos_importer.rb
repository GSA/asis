class FlickrPhotosImporter
  include Sidekiq::Worker
  sidekiq_options unique: true

  MAX_PHOTOS_PER_REQUEST = 500
  DAYS_BACK_TO_CHECK_FOR_UPDATES = 1
  EXTRA_FIELDS = "description, date_upload, date_taken, owner_name, tags, views, url_q, url_o"
  OPTIONS = { per_page: MAX_PHOTOS_PER_REQUEST, extras: EXTRA_FIELDS }

  def perform(id, profile_type, days_ago = nil)
    page, pages = 1, 1
    min_ts = days_ago.present? ? days_ago.days.ago.to_i : 0
    oldest_retrieved_ts = Time.now.to_i
    while page <= pages && oldest_retrieved_ts >= min_ts
      photos = get_photos(id, profile_type, OPTIONS.merge(page: page))
      Rails.logger.info("Storing #{photos.count} photos from page #{page} of #{pages} for Flickr #{profile_type} profile #{id}")
      stored_photos = store_photos(photos, profile_type)
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
  end

  def get_user_photos(id, options)
    FlickRaw::Flickr.new.people.getPublicPhotos(options.merge(user_id: id)) rescue nil
  end

  def get_group_photos(id, options)
    FlickRaw::Flickr.new.groups.pools.getPhotos(options.merge(group_id: id)) rescue nil
  end

  def store_photos(photos, profile_type)
    photos.collect do |photo|
      store_photo(photo, profile_type)
    end.compact.select do |photo|
      photo.persisted?
    end
  end

  def store_photo(photo, profile_type)
    tags = photo.tags.try(:split) || []
    attributes = { id: photo.id, owner: photo.owner, profile_type: profile_type, tags: strip_irrelevant_tags(tags),
                   title: photo.title.squish, description: photo.description.squish, taken_at: photo.datetaken,
                   popularity: photo.views, url: flickr_url(photo.owner, photo.id), thumbnail_url: photo.url_q }
    FlickrPhoto.create(attributes, { op_type: 'create' })
  rescue Elasticsearch::Transport::Transport::Errors::Conflict => e
    nil
  rescue Exception => e
    Rails.logger.warn("Trouble storing Flickr photo #{photo.inspect}: #{e}")
    nil
  end

  def flickr_url(owner, flickr_id)
    "http://www.flickr.com/photos/#{owner}/#{flickr_id}/"
  end

  def last_uploaded_ts(photos)
    photos.to_a.last.dateupload.to_i
  rescue Exception => e
    Rails.logger.warn("Trouble getting oldest upload date from photo #{photos.to_a.last}: #{e}")
    Time.now.to_i
  end

  def strip_irrelevant_tags(tags)
    tags.reject { |tag| tag.include?(':') }
  end

end