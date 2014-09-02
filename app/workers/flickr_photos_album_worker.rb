class FlickrPhotosAlbumWorker
  include Sidekiq::Worker

  def perform(flickr_profile_id)
    photo_filter = PhotoFilter.new('owner', flickr_profile_id)
    iterator = AlbumDetectionPhotoIterator.new(FlickrPhoto, photo_filter.query_body)
    iterator.run
  end

end