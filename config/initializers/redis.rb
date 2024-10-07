# frozen_string_literal: true

redis_url = ENV['REDIS_SYSTEM_URL'] || 'redis://localhost:6379'
$redis = Redis.new(url: redis_url)

# Log the Redis URL to confirm it's set correctly
Rails.logger.info "Redis URL: #{ENV.fetch('REDIS_SYSTEM_URL', 'localhost')}"

