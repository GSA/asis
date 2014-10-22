class MrssPhoto
  include Elasticsearch::Persistence::Model
  include IndexablePhoto

  attribute :mrss_url, String, mapping: { type: 'string', analyzer: 'keyword' }
  attribute :title, String, mapping: { type: 'string', analyzer: 'en_analyzer', copy_to: 'bigram' }
  attribute :description, String, mapping: { type: 'string', analyzer: 'en_analyzer', copy_to: 'bigram' }

  validates :mrss_url, presence: true

  def generate_album_name
    [self.mrss_url, self.taken_at, self.id].join(':')
  end

end