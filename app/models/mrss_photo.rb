# frozen_string_literal: true

class MrssPhoto
  include Elasticsearch::Persistence::Model
  include IndexablePhoto

  attribute :mrss_names, String, mapping: ElasticSettings::KEYWORD
  attribute :title, String, mapping: { type: 'text', analyzer: 'en_analyzer', copy_to: 'bigram' }
  attribute :description, String, mapping: { type: 'text', analyzer: 'en_analyzer', copy_to: 'bigram' }

  def generate_album_name
    [mrss_names, taken_at, id].join(':')
  end
end
