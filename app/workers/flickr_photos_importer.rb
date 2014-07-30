class FlickrPhotosImporter
  include Sidekiq::Worker
  sidekiq_options unique: true

  MAX_PHOTOS_PER_REQUEST = 500
  DAYS_BACK_TO_CHECK_FOR_UPDATES = 7
  EXTRA_FIELDS = "description, date_upload, date_taken, owner_name, tags, views, url_q, url_o"
  OPTIONS = { per_page: MAX_PHOTOS_PER_REQUEST, extras: EXTRA_FIELDS }

  def perform(id, type, days_ago = nil)
    page, pages = 1, 1
    min_ts = days_ago.present? ? days_ago.days.ago.to_i : 0
    oldest_retrieved_ts = Time.now.to_i
    while page <= pages && oldest_retrieved_ts >= min_ts
      photos = get_photos(id, type, OPTIONS.merge(page: page))
      Rails.logger.info("Storing up to #{photos.count} photos from page #{page} of #{pages} for Flickr #{type} profile #{id}")
      store_photos(photos, type)
      pages = photos.pages
      page += 1
      oldest_retrieved_ts = last_uploaded_ts(photos)
    end
  end

  def self.refresh
    FlickrProfile.all.each do |flickr_profile|
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

  def store_photos(photos, type)
    photos.each do |photo|
      store_photo(photo, type)
    end
  end

  def store_photo(photo, type)
    FlickrPhoto.create(id: photo.id,
                       owner: photo.owner,
                       profile_type: type,
                       tags: photo.tags.split,
                       title: photo.title,
                       description: photo.description,
                       taken_at: photo.datetaken,
                       popularity: photo.views,
                       url: flickr_url(photo.owner, photo.id),
                       thumbnail_url: photo.url_q)
  rescue Exception => e
    Rails.logger.warn("Trouble storing Flickr photo #{photo.inspect}: #{e}")
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

end