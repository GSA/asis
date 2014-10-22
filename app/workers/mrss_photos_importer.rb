class MrssPhotosImporter
  include Sidekiq::Worker
  sidekiq_options unique: true

  FEEDJIRA_OPTIONS = { user_agent: "Oasis", timeout: 20, compress: true, max_redirects: 3 }

  def perform(mrss_url)
    @mrss_url = mrss_url
    photos = get_photos
    return unless photos.present?
    Rails.logger.info("Storing #{photos.count} photos for MRSS feed #{@mrss_url}")
    stored_photos = store_photos(photos)
    stored_photos.each { |photo| AlbumDetector.detect_albums!(photo) }
  end

  def self.refresh
    MrssProfile.find_each do |mrss_profile|
      MrssPhotosImporter.perform_async(mrss_profile.id)
    end
  end

  private

  def get_photos
    feed = Feedjira::Feed.fetch_and_parse(@mrss_url, FEEDJIRA_OPTIONS)
    feed.entries
  rescue Exception => e
    Rails.logger.warn("Trouble fetching MRSS photos for URL: #{@mrss_url}: #{e}")
    nil
  end

  def store_photos(mrss_entries)
    mrss_entries.collect do |mrss_entry|
      store_photo(mrss_entry)
    end.compact.select do |mrss_photo|
      mrss_photo.persisted?
    end
  end

  def store_photo(mrss_entry)
    attributes = get_attributes(mrss_entry)
    MrssPhoto.create(attributes, { op_type: 'create' })
  rescue Elasticsearch::Transport::Transport::Errors::Conflict => e
    nil
  rescue Exception => e
    Rails.logger.warn("Trouble storing MRSS photo #{mrss_entry}: #{e}")
    nil
  end

  def get_attributes(mrss_entry)
    { id: mrss_entry.entry_id, mrss_url: @mrss_url, title: mrss_entry.title, description: mrss_entry.summary,
      taken_at: mrss_entry.published, url: mrss_entry.url, thumbnail_url: mrss_entry.thumbnail_url }
  end

end