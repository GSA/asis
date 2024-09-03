# frozen_string_literal: true

require 'sidekiq/web'
Rails.application.routes.draw do
  mount Api::Base => '/api'

  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(username, ENV['SIDEKIQ_USERNAME']) &
      ActiveSupport::SecurityUtils.secure_compare(password, ENV['SIDEKIQ_PASSWORD'])
  end if Rails.env.production?

  mount Sidekiq::Web => '/sidekiq'
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check
end
