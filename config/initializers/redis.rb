# frozen_string_literal: true

redis_url = ENV['REDIS_HOST'] || 'redis://localhost:6379'
$redis = Redis.new(url: redis_url)

# Log the Redis URL to confirm it's set correctly
Rails.logger.info "Redis URL: #{redis_url}"

