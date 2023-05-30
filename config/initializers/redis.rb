# frozen_string_literal: true

sidekiq = Rails.configuration.sidekiq

# rubocop:disable Style/GlobalVars
$redis = Redis.new(url: sidekiq['redis_url'], namespace: sidekiq['namespace'])
# rubocop:enable Style/GlobalVars
