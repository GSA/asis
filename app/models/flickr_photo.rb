class FlickrPhoto
  include Elasticsearch::Persistence::Model
  include IndexablePhoto

  attribute :owner, String, mapping: ElasticSettings::KEYWORD
  attribute :groups, String, mapping: ElasticSettings::KEYWORD
  attribute :title, String, mapping: { type: 'text', analyzer: 'en_analyzer', copy_to: 'bigram' }
  attribute :description, String, mapping: { type: 'text', analyzer: 'en_analyzer', copy_to: 'bigram' }

  validates :owner, presence: true
  validates :title, presence: true

  def generate_album_name
    [self.owner, self.taken_at, self.id].join(':')
  end

end
