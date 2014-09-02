class InstagramPhotosImporter
  include Sidekiq::Worker
  sidekiq_options unique: true

  MAX_PHOTOS_PER_REQUEST = -1
  DAYS_BACK_TO_CHECK_FOR_UPDATES = 1

  def perform(profile_id, days_ago = nil)
    options = { count: MAX_PHOTOS_PER_REQUEST }
    options.merge!(min_timestamp: days_ago.days.ago.to_i) if days_ago
    instagram_client = Instagram.client(access_token: INSTAGRAM_ACCESS_TOKEN)
    photos = instagram_client.user_recent_media(profile_id, options)
    return unless photos.present?
    Rails.logger.info("Storing #{photos.count} photos for Instagram profile #{profile_id}")
    stored_photos = store_photos(photos)
    stored_photos.each { |photo| AlbumDetector.detect_albums!(photo) }
  end

  def self.refresh
    InstagramProfile.find_each do |instagram_profile|
      InstagramPhotosImporter.perform_async(instagram_profile.id, DAYS_BACK_TO_CHECK_FOR_UPDATES)
    end
  end

  private

  def store_photos(photos)
    photos.collect do |photo|
      store_photo(photo)
    end.compact.select do |photo|
      photo.persisted?
    end
  end

  def store_photo(photo)
    attributes = { id: photo.id, username: photo.user.username, tags: photo.tags, caption: photo.caption.text,
                   taken_at: Time.at(photo.created_time.to_i).utc, popularity: photo.likes['count'] + photo.comments['count'],
                   url: photo.link, thumbnail_url: photo.images.thumbnail.url }
    InstagramPhoto.create(attributes, { op_type: 'create' })
  rescue Elasticsearch::Transport::Transport::Errors::Conflict => e
    nil
  rescue Exception => e
    Rails.logger.warn("Trouble storing Instagram photo #{photo}: #{e}")
    nil
  end

end