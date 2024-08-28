# frozen_string_literal: true

require_relative 'boot'

require "rails"
# Pick the frameworks you want:
# require "active_model/railtie"
# require "active_job/railtie"
# require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
# require "action_view/railtie"
# require "action_cable/engine"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Oasis
  APP_NAME = 'asis'
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Set default cache format
    config.active_support.cache_format_version = 7.1
    config.active_support.disable_to_s_conversion = false
    config.generators.system_tests = nil
    config.elasticsearch = config_for(:elasticsearch)
    config.sidekiq       = config_for(:sidekiq)
    config.flickr        = config_for(:flickr)

    config.semantic_logger.application = ENV.fetch('APP_NAME', APP_NAME)
    config.secret_key_base = ENV["ASIS_SECRET_KEY_BASE"]
  end
end
