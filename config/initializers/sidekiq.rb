# frozen_string_literal: true

yaml = YAML.load_file("#{Rails.root}/config/sidekiq.yml")

Sidekiq.configure_server do |config|
  config.redis = { url: yaml['url'], namespace: yaml['namespace'] }
end

Sidekiq.configure_client do |config|
  config.redis = { url: yaml['url'], namespace: yaml['namespace'] }
end
