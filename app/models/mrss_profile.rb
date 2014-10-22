class MrssProfile
  include Elasticsearch::Persistence::Model
  include AliasedIndex

  settings(ElasticSettings::COMMON)

  attribute :name, String, mapping: ElasticSettings::KEYWORD
  validates :name, presence: true

  after_save { Rails.logger.info "Successfuly saved #{self.class.name.tableize}: #{self}" }

  def initialize(options)
    assign_name
    super(options)
  end

  def self.mrss_urls_from_names(mrss_names)
    return nil unless mrss_names.present?
    mrss_names_filter = TermsFilter.new('name', mrss_names)
    all(query: mrss_names_filter.query_body).collect(&:id)
  end

  private

  REDIS_KEY_NAME = "#{self.name}.name"

  def assign_name
    self.name = $redis.incr(REDIS_KEY_NAME)
  end

end