# frozen_string_literal: true

if Rails.env.production?
  sidekiq = YAML.load_file("#{Rails.root}/config/sidekiq.yml")
else
  sidekiq = Rails.configuration.sidekiq
end

Sidekiq.configure_server do |config|
  config.redis = { url: sidekiq['url'] }
end

Sidekiq.configure_client do |config|
  config.redis = { url: sidekiq['url'] }
end
