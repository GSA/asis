class AlbumDetector
  MAX_PHOTOS_PER_ALBUM = 10000
  MIN_SIMILAR_PHOTOS = 4

  def initialize(photo, query_fields_thresholds_hash, filter_fields)
    @photo = photo
    @query_fields_thresholds_hash = query_fields_thresholds_hash
    @filter_fields = filter_fields
  end

  def album
    album_results = more_like_this
    first_bucket_size = album_results['aggregations']['scores_histogram']['buckets'].first['doc_count'] rescue 0
    first_bucket_size >= MIN_SIMILAR_PHOTOS ? album_results['hits']['hits'].first(first_bucket_size) : []
  end

  def self.detect_albums!(photo)
    photo_klass = photo.class
    photo_source = photo_klass.name.split(/(?=[A-Z])/).first
    album_detector_klass = "#{photo_source}AlbumDetector".constantize
    assign_default_album(photo)
    album_detector = album_detector_klass.new(photo)
    album = album_detector.album
    ids = album.collect { |hit| hit['_id'] }
    if ids.present?
      Rails.logger.info "Setting #{photo_klass.name} album: #{photo.album} for ids: #{ids}"
      bulk_assign(ids, photo.album, photo.class.index_name, photo._type)
    end
    ids
  end

  private

  def self.assign_default_album(photo)
    options = photo._version.present? ? { version: photo._version } : {}
    photo.update({ album: photo.generate_album_name }, options)
  rescue Elasticsearch::Transport::Transport::Errors::Conflict => e
    Rails.logger.warn "Photo album probably got assigned already in prior album detection: #{e}"
  end

  def self.bulk_assign(ids, album, index, type)
    body = ids.reduce([]) do |bulk_array, id|
      meta_data = { _index: index, _type: type, _id: id }
      bulk_array << { update: meta_data }
      bulk_array << { doc: { album: album } }
    end
    Elasticsearch::Persistence.client.bulk(body: body)
  end

  def more_like_this
    album_detection_query = AlbumDetection.new(@photo, @query_fields_thresholds_hash, @filter_fields)
    params = { index: @photo.class.index_name, body: album_detection_query.query_body, size: MAX_PHOTOS_PER_ALBUM }
    Elasticsearch::Persistence.client.search(params)
  end


end