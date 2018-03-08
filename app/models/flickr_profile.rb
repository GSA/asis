# frozen_string_literal: true

class FlickrProfile
  include Elasticsearch::Persistence::Model
  include AliasedIndex

  settings(ElasticSettings::COMMON)

  attribute :name, String, mapping: ElasticSettings::KEYWORD
  validates :name, presence: true
  attribute :profile_type, String, mapping: ElasticSettings::KEYWORD
  validates :profile_type, presence: true

  after_save { Rails.logger.info "Successfuly saved #{self.class.name.tableize}: #{self}" }
end
