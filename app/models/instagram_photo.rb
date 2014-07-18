class InstagramPhoto
  include Elasticsearch::Persistence::Model
  index_name [Rails.env, Rails.application.engine_name.split('_').first, self.name.tableize].join('-')

  settings ElasticSettings::COMMON do
    mappings dynamic: 'true' do
      indexes :bigram, analyzer: 'bigram_analyzer', type: 'string'
    end
  end

  attribute :username, String, mapping: ElasticSettings::KEYWORD
  attribute :tags, String, mapping: ElasticSettings::KEYWORD
  attribute :url, String, mapping: ElasticSettings::KEYWORD
  attribute :thumbnail_url, String, mapping: ElasticSettings::KEYWORD
  attribute :caption, String, mapping: { type: 'string', analyzer: 'en_analyzer', copy_to: 'bigram' }
  attribute :popularity, Integer, default: 0, mapping: { type: 'integer', index: :not_analyzed }
  attribute :taken_at, Date

  validates :username, presence: true
  validates :caption, presence: true
  validates :url, presence: true
  validates :thumbnail_url, presence: true
  validates :taken_at, presence: true

  after_save { Rails.logger.info "Successfuly saved #{self.class.name.tableize}: #{self}" }
end