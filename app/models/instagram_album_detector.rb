# frozen_string_literal: true

# Instagram is being decommissioned per
# https://cm-jira.usa.gov/browse/SRCH-50
class InstagramAlbumDetector < AlbumDetector
  QUERY_FIELDS_THRESHOLD_HASH = { tags: 0.75, caption: 0.8 }.freeze
  FILTER_FIELDS = %w[username taken_at].freeze

  def initialize(instagram_photo)
    instagram_photo.username = instagram_photo.username.downcase
    super(instagram_photo, QUERY_FIELDS_THRESHOLD_HASH, FILTER_FIELDS)
  end
end
