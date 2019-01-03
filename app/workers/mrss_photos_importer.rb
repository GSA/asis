# frozen_string_literal: true

class MrssPhotosImporter
  include Sidekiq::Worker
  sidekiq_options unique: true

  def perform(mrss_name)
    @mrss = MrssProfile.find_by_name mrss_name
    photos = get_photos
    return if photos.blank?
    Rails.logger.info("Storing #{photos.count} photos for MRSS feed #{@mrss.id}")
    stored_photos = store_photos(photos)
    stored_photos.each { |photo| AlbumDetector.detect_albums!(photo) }
  end

  def self.refresh
    MrssProfile.find_each do |mrss_profile|
      MrssPhotosImporter.perform_async(mrss_profile.name)
    end
  end

  private

  def get_photos
    xml = fetch_xml(@mrss.id)
    feed = Feedjira::Feed.parse(xml)
    feed.entries
  rescue StandardError => e
    Rails.logger.warn("Trouble fetching MRSS photos for URL: #{@mrss.id}: #{e}")
    nil
  end

  def store_photos(mrss_entries)
    mrss_entries.collect do |mrss_entry|
      store_photo(mrss_entry)
    end.compact.select(&:persisted?)
  end

  def store_photo(mrss_entry)
    attributes = get_attributes(mrss_entry)
    MrssPhoto.create(attributes, op_type: 'create')
  rescue Elasticsearch::Transport::Transport::Errors::Conflict
    script = {
      source: 'if (ctx._source.mrss_names.contains(new_name)) { ctx.op = "none" } else { ctx._source.mrss_names += new_name }',
      params: { new_name: @mrss.name },
      lang: 'groovy'
    }
    MrssPhoto.gateway.update(mrss_entry.entry_id, script: script)
    nil
  rescue StandardError => e
    Rails.logger.warn("Trouble storing MRSS photo #{mrss_entry}: #{e}")
    nil
  end

  def get_attributes(mrss_entry)
    { id: mrss_entry.entry_id, mrss_names: [@mrss.name], title: mrss_entry.title, description: mrss_entry.summary,
      taken_at: mrss_entry.published, url: mrss_entry.url, thumbnail_url: mrss_entry.thumbnail_url }
  end

  def fetch_xml(url)
    HTTP.headers(user_agent: 'Oasis').timeout(30).follow.get(url).to_s
  end
end
