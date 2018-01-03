source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '5.1.4'

# Temporarily limiting rake version:
# #http://stackoverflow.com/questions/35893584/nomethoderror-undefined-method-last-comment-after-upgrading-to-rake-11
gem 'rake', '~> 10.0'

gem 'grape', '~> 1.0.0'

gem 'jbuilder', '~> 2.6.4'

gem 'capistrano', '~> 3.3.5'
gem 'capistrano-bundler', '~> 1.1.3'
gem 'capistrano-sidekiq', '~> 0.4.0'

gem "elasticsearch-persistence", '~> 5.0', require: 'elasticsearch/persistence/model'
gem 'elasticsearch-api', '~> 6.0'
gem 'elasticsearch-model', '~> 5.0'
gem 'elasticsearch-transport', '~> 6.0'
gem 'hashie', '~> 3.3.2' # Hashie::Mash@3.5 will emit warning on key collision. Lock to 3.3.2 to avoid code change.
gem 'instagram', '~> 1.1.3'
gem 'flickraw', '~> 0.9.8'
gem 'sidekiq', '< 6'
gem 'redis-namespace', '~> 1.6.0' # use redis database index instead?
gem 'mock_redis', '~> 0.17.3'
gem 'sidekiq-unique-jobs', '3.0.11' # sidekiq-unique-jobs > 3.0.11 broke spec
gem 'sidekiq-failures', '~> 1.0.0'
gem 'sinatra', '>= 2.0', :require => nil
gem 'whenever', '~> 0.9.4', :require => false

gem 'newrelic_rpm', '~> 4.2.0.334'
gem 'airbrake', '~> 7.1.1'

gem 'feedjira', '~> 2.1.1'

group :development, :test do
  gem 'puma', '~> 3.11'

  gem 'binding_of_caller'
  gem 'pry-rails'
  gem 'rspec-rails', '~> 3.7.2'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'rspec-sidekiq', '~> 3.0.1'
  gem 'simplecov', '~> 0.7.1'
  gem 'rspec_junit_formatter', '~> 0.2.3'
end
