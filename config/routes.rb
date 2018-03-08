# frozen_string_literal: true

require 'sidekiq/web'
Rails.application.routes.draw do
  mount API::Base => '/api'
  mount Sidekiq::Web => '/sidekiq'
end
