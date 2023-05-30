# frozen_string_literal: true

sidekiq = Rails.configuration.sidekiq

Sidekiq.configure_server do |config|
  config.redis = { url: sidekiq['redis_url'], namespace: sidekiq['namespace'] }
end

Sidekiq.configure_client do |config|
  config.redis = { url: sidekiq['redis_url'], namespace: sidekiq['namespace'] }
end
