class MrssPhoto
  include Elasticsearch::Persistence::Model
  include IndexablePhoto

  attribute :mrss_name, String, mapping: ElasticSettings::KEYWORD
  attribute :title, String, mapping: { type: 'string', analyzer: 'en_analyzer', copy_to: 'bigram' }
  attribute :description, String, mapping: { type: 'string', analyzer: 'en_analyzer', copy_to: 'bigram' }

  validates :mrss_name, presence: true

  def generate_album_name
    [self.mrss_name, self.taken_at, self.id].join(':')
  end

end