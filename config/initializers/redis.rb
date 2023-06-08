# frozen_string_literal: true

if Rails.env.production?
  sidekiq = YAML.load_file("#{Rails.root}/config/sidekiq.yml")
else
  sidekiq = Rails.configuration.sidekiq
end

# rubocop:disable Style/GlobalVars
$redis = Redis.new(url: sidekiq['redis_url'], namespace: sidekiq['namespace'])
# rubocop:enable Style/GlobalVars
