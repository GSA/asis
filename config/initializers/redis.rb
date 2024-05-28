# frozen_string_literal: true

if Rails.env.production?
  sidekiq = Rails.application.config_for(:sidekiq)
else
  sidekiq = Rails.configuration.sidekiq
end

# rubocop:disable Style/GlobalVars
$redis = Redis.new(url: sidekiq['url'])
# rubocop:enable Style/GlobalVars
