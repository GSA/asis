if Rails.env.development?
  Sidekiq.configure_server do |config|
    config.poll_interval = 1
  end
end