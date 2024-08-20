# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 7.1.0'
gem 'rake', '~> 13.0.6'
gem 'grape', '~> 1.7.0'
gem 'jbuilder', '~> 2.11.5'
gem 'elasticsearch-api', '~> 6.0'
gem 'elasticsearch-model', '~> 5.0'
gem 'elasticsearch-persistence', '~> 5.0', require: 'elasticsearch/persistence/model'
gem 'elasticsearch-transport', '~> 6.0'
gem 'flickraw', '~> 0.9.8'
gem 'hashie', '~> 3.5.7'
gem 'mock_redis', '~> 0.17.3'
gem 'redis-namespace', '~> 1.10.0' # use redis database index instead?
gem 'sidekiq', '~> 7.1.3'
gem 'sidekiq-failures', '~> 1.0.0'
gem 'sidekiq-unique-jobs', '~> 8.0.9'
gem 'whenever', '~> 0.9.4', require: false
gem 'newrelic_rpm', '~> 9.10'
gem 'feedjira', '~> 2.2.0'
gem 'rails_semantic_logger', '~> 4.14'
gem 'puma', '~> 5.6'
gem 'dotenv', '~> 3.1'

group :development, :test do
  gem 'binding_of_caller'
  gem 'pry-rails'
  gem 'rspec-rails', '~> 5.0'
  gem 'debug'
  gem 'capistrano',          require: false
  gem 'capistrano-newrelic', require: false
  gem 'capistrano-rails',    require: false
  gem 'capistrano-rbenv',    require: false
  gem 'capistrano-sidekiq',  require: false
  gem 'capistrano3-puma',    require: false
  gem 'listen', '~> 3.8.0'
end

group :development do
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  # Bumping searchgov_style? Be sure to update rubocop, if possible,
  # and set the Rubocop channel in .codeclimate.yml to match the updated rubocop version.
  gem 'searchgov_style', '~> 0.1', require: false
  gem 'rubocop', '1.48.1', require: false
end

group :test do
  gem 'rspec-sidekiq', '~> 3.0.1'
  gem 'rspec_junit_formatter', '~> 0.4.1'
  gem 'simplecov', '~> 0.16.1'
  gem 'webmock', '~> 3.18'
end


