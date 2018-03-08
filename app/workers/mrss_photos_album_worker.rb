# frozen_string_literal: true

class MrssPhotosAlbumWorker
  include Sidekiq::Worker

  def perform(mrss_url)
    photo_filter = PhotoFilter.new('mrss_url', mrss_url)
    iterator = AlbumDetectionPhotoIterator.new(MrssPhoto, photo_filter.query_body)
    iterator.run
  end
end
