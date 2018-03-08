# frozen_string_literal: true

class MrssAlbumDetector < AlbumDetector
  QUERY_FIELDS_THRESHOLD_HASH = { tags: 0.75, title: 0.5, description: 0.8 }.freeze
  FILTER_FIELDS = %w[mrss_names taken_at].freeze

  def initialize(mrss_photo)
    super(mrss_photo, QUERY_FIELDS_THRESHOLD_HASH, FILTER_FIELDS)
  end
end
