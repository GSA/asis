# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = { host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'] }
end

Sidekiq.configure_client do |config|
  config.redis = { host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'] }
end
