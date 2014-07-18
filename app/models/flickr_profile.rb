class FlickrProfile
  include Elasticsearch::Persistence::Model
  index_name [Rails.env, Rails.application.engine_name.split('_').first, self.name.tableize].join('-')
  settings(ElasticSettings::COMMON)

  attribute :name, String, mapping: ElasticSettings::KEYWORD
  validates :name, presence: true
  attribute :profile_type, String, mapping: ElasticSettings::KEYWORD
  validates :profile_type, presence: true

  after_save { Rails.logger.info "Successfuly saved #{self.class.name.tableize}: #{self}" }

end