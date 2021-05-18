# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.2.0'

gem 'rake', '~> 12.3.2'

gem 'grape', '~> 1.3.2'

gem 'jbuilder', '~> 2.6.4'

gem 'capistrano', '~> 3.3.5'
gem 'capistrano-bundler', '~> 1.1.3'
gem 'capistrano-sidekiq', '~> 0.4.0'

gem 'elasticsearch-api', '~> 6.0'
gem 'elasticsearch-model', '~> 5.0'
gem 'elasticsearch-persistence', '~> 5.0', require: 'elasticsearch/persistence/model'
gem 'elasticsearch-transport', '~> 6.0'
gem 'flickraw', '~> 0.9.8'
gem 'hashie', '~> 3.5.7'
gem 'instagram-continued', '~> 1.4.0'
gem 'mock_redis', '~> 0.17.3'
gem 'redis-namespace', '~> 1.6.0' # use redis database index instead?
gem 'sidekiq', '< 6'
gem 'sidekiq-failures', '~> 1.0.0'
gem 'sidekiq-unique-jobs', '3.0.11' # sidekiq-unique-jobs > 3.0.11 broke spec
gem 'sinatra', '~> 2.0.2', require: nil
gem 'whenever', '~> 0.9.4', require: false

gem 'airbrake', '~> 7.1.1'
gem 'newrelic_rpm', '~> 4.2.0.334'

gem 'feedjira', '~> 2.2.0'
gem 'http', '~> 4.0.0'

group :development, :test do
  gem 'puma', '~> 4.3'
  gem 'binding_of_caller'
  gem 'pry-rails'
  gem 'rspec-rails', '~> 3.8.2'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  # Bumping searchgov_style? Be sure to update the Rubocop channel in .codeclimate.yml
  # to match the channel in searchgov_style
  gem 'searchgov_style', '~> 0.1', require: false
end

group :test do
  gem 'rspec-sidekiq', '~> 3.0.1'
  gem 'rspec_junit_formatter', '~> 0.4.1'
  gem 'simplecov', '~> 0.16.1'
  gem 'webmock', '~> 3.5.1'
end
