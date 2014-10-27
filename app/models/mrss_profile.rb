class MrssProfile
  include Elasticsearch::Persistence::Model
  include AliasedIndex

  settings(ElasticSettings::COMMON)

  attribute :name, String, mapping: ElasticSettings::KEYWORD
  validates :name, presence: true
  validates :id, presence: true

  after_save { Rails.logger.info "Successfuly saved #{self.class.name.tableize}: #{self}" }

  def initialize(options)
    assign_name
    super(options)
  end

  def self.find_by_name(mrss_name)
    mrss_names_filter = TermsFilter.new('name', [mrss_name])
    all(query: mrss_names_filter.query_body).first
  end

  def self.create_or_find_by_id(id)
    MrssProfile.create({ id: id }, { op_type: 'create' })
  rescue Elasticsearch::Transport::Transport::Errors::Conflict => e
    MrssProfile.find(id)
  end

  private

  REDIS_KEY_NAME = "#{self.name}.name"

  def assign_name
    self.name = $redis.incr(REDIS_KEY_NAME)
  end

end