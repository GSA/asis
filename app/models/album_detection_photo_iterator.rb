# frozen_string_literal: true

class AlbumDetectionPhotoIterator
  def initialize(klass, query_body)
    @klass = klass
    @query_body = query_body
  end

  def run
    seen = Set.new
    @klass.find_each(size: 1000, scroll: '20m', query: @query_body) do |photo|
      next if seen.include?(photo.id)
      ids = AlbumDetector.detect_albums!(photo)
      seen.merge(ids)
    end
  end
end
