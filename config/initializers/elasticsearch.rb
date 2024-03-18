# frozen_string_literal: true

ES_CONFIG = Rails.application.config_for(:elasticsearch).freeze

Elasticsearch::Persistence.client = Elasticsearch::Client.new(ES_CONFIG.merge({ randomize_hosts: true, retry_on_failure: true, reload_connections: false, reload_on_failure: false }))

if Rails.configuration.elasticsearch['log']
  logger = ActiveSupport::Logger.new("log/#{Rails.env}.log")
  logger.level = Rails.configuration.elasticsearch['log_level']
  logger.formatter = proc do |severity, time, _progname, msg|
    "\e[2m[ES][#{time.utc.iso8601(6)}][#{severity}] #{msg}\n\e[0m"
  end
  Elasticsearch::Persistence.client.transport.logger = logger
end
