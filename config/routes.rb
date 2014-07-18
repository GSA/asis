require 'sidekiq/web'
Oasis::Application.routes.draw do
  mount API::Base => '/api'
  mount Sidekiq::Web => '/sidekiq'
end
