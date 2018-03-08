# frozen_string_literal: true

Elasticsearch::Persistence.client = Elasticsearch::Client.new(
  log: Rails.env.development?,
  hosts: Rails.configuration.elasticsearch['hosts'],
  user: Rails.configuration.elasticsearch['user'],
  password: Rails.configuration.elasticsearch['password'],
  randomize_hosts: true,
  retry_on_failure: true,
  reload_connections: true
)

if Rails.env.development?
  logger = ActiveSupport::Logger.new(STDERR)
  logger.level = Logger::DEBUG
  logger.formatter = proc { |_s, _d, _p, m| "\e[2m#{m}\n\e[0m" }
  Elasticsearch::Persistence.client.transport.logger = logger

  puts 'Ensuring Elasticsearch development indexes and aliases are available....'
  Dir[Rails.root.join('app', 'models', '*.rb')].map do |f|
    klass = File.basename(f, '.*').camelize.constantize
    klass.create_index_and_alias! if klass.respond_to?(:create_index_and_alias!) && !klass.alias_exists?
  end
end
