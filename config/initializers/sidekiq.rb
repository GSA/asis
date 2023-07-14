# frozen_string_literal: true

if Rails.env.production?
  sidekiq = YAML.load_file("#{Rails.root}/config/sidekiq.yml")
else
  sidekiq = Rails.configuration.sidekiq
end

Sidekiq.configure_server do |config|
  if ENV['OLD']
    # We'll continue to poll for old scheduled jobs and retries
    config.redis = { url: 'redis://localhost:6379/0', namespace: sidekiq['namespace']}
  else
    config.redis = { url: sidekiq['url'] }
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: sidekiq['url'] }
end
