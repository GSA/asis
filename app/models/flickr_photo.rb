class FlickrPhoto
  include Elasticsearch::Persistence::Model
  index_name [Rails.env, Rails.application.engine_name.split('_').first, self.name.tableize].join('-')

  settings ElasticSettings::COMMON do
    mappings dynamic: 'true' do
      indexes :bigram, analyzer: 'bigram_analyzer', type: 'string'
    end
  end

  attribute :owner, String, mapping: ElasticSettings::KEYWORD
  attribute :profile_type, String, mapping: ElasticSettings::KEYWORD
  attribute :title, String, mapping: { type: 'string', analyzer: 'en_analyzer', copy_to: 'bigram' }
  attribute :description, String, mapping: { type: 'string', analyzer: 'en_analyzer', copy_to: 'bigram' }
  attribute :taken_at, Date
  attribute :tags, String, mapping: ElasticSettings::KEYWORD
  attribute :url, String, mapping: ElasticSettings::KEYWORD
  attribute :thumbnail_url, String, mapping: ElasticSettings::KEYWORD
  attribute :popularity, Integer, default: 0, mapping: { type: 'integer', index: :not_analyzed }

  validates :owner, presence: true
  validates :profile_type, presence: true
  validates :title, presence: true
  validates :url, presence: true
  validates :thumbnail_url, presence: true
  validates :taken_at, presence: true

  after_save { Rails.logger.info "Successfuly saved #{self.class.name.tableize}: #{self}" }
end