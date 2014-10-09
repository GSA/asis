class FlickrAlbumDetector < AlbumDetector
  QUERY_FIELDS_THRESHOLD_HASH = { tags: 0.75, title: 0.5, description: 0.8 }
  FILTER_FIELDS = %w(owner groups taken_at)

  def initialize(flickr_photo)
    flickr_photo.owner.downcase!
    super(flickr_photo, QUERY_FIELDS_THRESHOLD_HASH, FILTER_FIELDS)
  end
end