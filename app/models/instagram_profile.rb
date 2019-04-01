# frozen_string_literal: true

# Instagram is being decommissioned per
# https://cm-jira.usa.gov/browse/SRCH-50
class InstagramProfile
  include Elasticsearch::Persistence::Model
  include AliasedIndex

  settings(ElasticSettings::COMMON)

  attribute :username, String, mapping: ElasticSettings::KEYWORD
  validates :username, presence: true

  after_save { Rails.logger.info "Successfuly saved #{self.class.name.tableize}: #{self}" }
end
