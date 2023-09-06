# frozen_string_literal: true

ES_CONFIG = Rails.application.config_for(:elasticsearch).freeze

Elasticsearch::Persistence.client = Elasticsearch::Client.new(ES_CONFIG.merge({ randomize_hosts: true, retry_on_failure: true, reload_connections: true}))

if Rails.configuration.elasticsearch['log']
  logger = ActiveSupport::Logger.new("log/#{Rails.env}.log")
  logger.level = Rails.configuration.elasticsearch['log_level']
  logger.formatter = proc do |severity, time, _progname, msg|
    "\e[2m[ES][#{time.utc.iso8601(6)}][#{severity}] #{msg}\n\e[0m"
  end
  Elasticsearch::Persistence.client.transport.logger = logger
end

if Rails.env.development?
  puts 'Ensuring Elasticsearch development indexes and aliases are available....'
  Dir[Rails.root.join('app', 'models', '*.rb')].map do |f|
    klass = File.basename(f, '.*').camelize.constantize
    klass.create_index_and_alias! if klass.respond_to?(:create_index_and_alias!) && !klass.alias_exists?
  end
end
