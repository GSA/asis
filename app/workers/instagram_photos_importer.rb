class InstagramPhotosImporter
  include Sidekiq::Worker
  sidekiq_options unique: true

  DAYS_BACK_TO_CHECK_FOR_UPDATES = 30

  def perform(profile_id, days_ago = nil)
    morepages = true
    max_id = nil
    options = {}
    options.merge!(min_timestamp: days_ago.days.ago.to_i) if days_ago
    while morepages do
      options.merge!(max_id: max_id) if max_id
      photos = get_photos(options, profile_id)
      if photos.present?
        max_id = photos.last.id
        Rails.logger.info("Storing #{photos.count} photos for Instagram profile #{profile_id}")
        stored_photos = store_photos(photos)
        stored_photos.each { |photo| AlbumDetector.detect_albums!(photo) }
      else
        morepages = false
      end
    end
  end

  def self.refresh
    InstagramProfile.find_each do |instagram_profile|
      InstagramPhotosImporter.perform_async(instagram_profile.id, DAYS_BACK_TO_CHECK_FOR_UPDATES)
    end
  end

  private

  def get_photos(options, profile_id)
    instagram_client = Instagram.client(access_token: Rails.configuration.instagram['access_token'])
    instagram_client.user_recent_media(profile_id, options)
  rescue Exception => e
    Rails.logger.warn("Trouble fetching Flickr photos for profile_id: #{profile_id}, options: #{options}: #{e}")
    nil
  end

  def store_photos(photos)
    photos.collect do |photo|
      store_photo(photo)
    end.compact.select do |photo|
      photo.persisted?
    end
  end

  def store_photo(photo)
    attributes = get_attributes(photo)
    InstagramPhoto.create(attributes, { op_type: 'create' })
  rescue Elasticsearch::Transport::Transport::Errors::Conflict => e
    InstagramPhoto.gateway.update(id: photo.id, popularity: compute_popularity(photo))
    nil
  rescue Exception => e
    Rails.logger.warn("Trouble storing Instagram photo #{photo}: #{e}")
    nil
  end

  def get_attributes(photo)
    { id: photo.id, username: photo.user.username, tags: photo.tags, caption: photo.caption.text,
      taken_at: Time.at(photo.created_time.to_i).utc, popularity: compute_popularity(photo),
      url: photo.link, thumbnail_url: photo.images.thumbnail.url }
  end

  def compute_popularity(photo)
    photo.likes['count'] + photo.comments['count']
  end

end
