# frozen_string_literal: true

# Instagram is being decommissioned per
# https://cm-jira.usa.gov/browse/SRCH-50
class InstagramPhoto
  include Elasticsearch::Persistence::Model
  include IndexablePhoto

  attribute :username, String, mapping: ElasticSettings::KEYWORD
  attribute :caption, String, mapping: { type: 'text', analyzer: 'en_analyzer', copy_to: 'bigram' }

  validates :username, presence: true
  validates :caption, presence: true

  def generate_album_name
    [username, taken_at, id].join(':')
  end
end
