yaml = YAML.load_file("#{Rails.root}/config/elasticsearch.yml")

Elasticsearch::Persistence.client = Elasticsearch::Client.new(log: Rails.env.development?, hosts: yaml['hosts'])

if Rails.env.development?
  logger = ActiveSupport::Logger.new(STDERR)
  logger.level = Logger::DEBUG
  logger.formatter = proc { |s, d, p, m| "\e[2m#{m}\n\e[0m" }
  Elasticsearch::Persistence.client.transport.logger = logger

  puts "Ensuring Elasticsearch development indexes and aliases are available...."
  Dir[Rails.root.join('app', 'models', '*.rb')].map do |f|
    klass = File.basename(f, '.*').camelize.constantize
    klass.create_index_and_alias! if klass.respond_to?(:create_index_and_alias!) and !klass.alias_exists?
  end
end
