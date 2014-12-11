class MrssPhoto
  include Elasticsearch::Persistence::Model
  include IndexablePhoto

  attribute :mrss_names, String, mapping: ElasticSettings::KEYWORD
  attribute :title, String, mapping: { type: 'string', analyzer: 'en_analyzer', copy_to: 'bigram' }
  attribute :description, String, mapping: { type: 'string', analyzer: 'en_analyzer', copy_to: 'bigram' }

  def generate_album_name
    [self.mrss_names, self.taken_at, self.id].join(':')
  end

end