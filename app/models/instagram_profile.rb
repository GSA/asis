class InstagramProfile
  include Elasticsearch::Persistence::Model
  index_name [Rails.env, Rails.application.engine_name.split('_').first, self.name.tableize].join('-')

  settings(ElasticSettings::COMMON)

  attribute :username, String, mapping: ElasticSettings::KEYWORD
  validates :username, presence: true

  after_save { Rails.logger.info "Successfuly saved #{self.class.name.tableize}: #{self}" }

end