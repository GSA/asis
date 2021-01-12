# frozen_string_literal: true

Elasticsearch::Persistence.client = Elasticsearch::Client.new(
  log: Rails.configuration.elasticsearch['log'],
  hosts: Rails.configuration.elasticsearch['hosts'],
  user: Rails.configuration.elasticsearch['user'],
  password: Rails.configuration.elasticsearch['password'],
  randomize_hosts: true,
  retry_on_failure: true,
  reload_connections: true
)

logger = ActiveSupport::Logger.new("log/#{Rails.env}.log")
logger.level = Rails.configuration.elasticsearch['log_level']
logger.formatter = proc do |severity, time, _progname, msg|
  "\e[2m[ES][#{time.utc.iso8601(6)}][#{severity}] #{msg}\n\e[0m"
end
Elasticsearch::Persistence.client.transport.logger = logger

if Rails.env.development?
  puts 'Ensuring Elasticsearch development indexes and aliases are available....'
  Dir[Rails.root.join('app', 'models', '*.rb')].map do |f|
    klass = File.basename(f, '.*').camelize.constantize
    klass.create_index_and_alias! if klass.respond_to?(:create_index_and_alias!) && !klass.alias_exists?
  end
end
