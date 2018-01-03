class InstagramPhoto
  include Elasticsearch::Persistence::Model
  include IndexablePhoto

  attribute :username, String, mapping: ElasticSettings::KEYWORD
  attribute :caption, String, mapping: { type: 'text', analyzer: 'en_analyzer', copy_to: 'bigram' }

  validates :username, presence: true
  validates :caption, presence: true

  def generate_album_name
    [self.username, self.taken_at, self.id].join(':')
  end

end
