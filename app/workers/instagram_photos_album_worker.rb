# frozen_string_literal: true

# Instagram is being decommissioned per
# https://cm-jira.usa.gov/browse/SRCH-50
class InstagramPhotosAlbumWorker
  include Sidekiq::Worker

  def perform(instagram_profile_username)
    photo_filter = PhotoFilter.new('username', instagram_profile_username.downcase)
    iterator = AlbumDetectionPhotoIterator.new(InstagramPhoto, photo_filter.query_body)
    iterator.run
  end
end
