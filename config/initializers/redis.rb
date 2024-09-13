# frozen_string_literal: true

$redis = Redis.new(url: ENV.fetch('REDIS_HOST', 'localhost'), port: ENV.fetch('REDIS_PORT', '6379'))

# Log the Redis URL to confirm it's set correctly
Rails.logger.info "Redis URL: #{ENV.fetch('REDIS_HOST', 'localhost')}"
