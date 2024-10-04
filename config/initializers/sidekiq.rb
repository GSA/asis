# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_SYSTEM_URL'] }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_SYSTEM_URL'] }
end

Sidekiq.configure_server do |config|
  config.logger = Logger.new('/home/search/asis/shared/log/sidekiq.log')
end