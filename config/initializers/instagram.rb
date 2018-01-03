require 'instagram'

Instagram.configure do |config|
  config.client_id = Rails.configuration.instagram['client_id']
  config.client_secret = Rails.configuration.instagram['client_secret']
end

INSTAGRAM_ACCESS_TOKEN = Rails.configuration.instagram['access_token']
