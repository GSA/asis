server 'web', user: 'search', roles: %w{web app}
server 'cron', user: 'search', roles: %w{sidekiq}
