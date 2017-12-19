source 'https://rubygems.org'
gem 'rails', '4.2.10'

# Temporarily limiting rake version:
# #http://stackoverflow.com/questions/35893584/nomethoderror-undefined-method-last-comment-after-upgrading-to-rake-11
gem 'rake', '~> 10.0'

gem 'grape', '~> 0.9.0'
gem 'thin', '~> 1.6.3'

gem 'jbuilder', '~> 2.2.5'

gem 'capistrano', '~> 3.3.5'
gem 'capistrano-bundler', '~> 1.1.3'
gem 'capistrano-sidekiq', '~> 0.4.0'

gem "elasticsearch-persistence", '~> 5.0', require: 'elasticsearch/persistence/model'
gem 'elasticsearch-api', '~> 6.0'
gem 'elasticsearch-model', '~> 5.0'
gem 'elasticsearch-transport', '~> 6.0'
gem 'instagram', '~> 1.1.3'
gem 'flickraw', '~> 0.9.8'
gem 'sidekiq', '~> 3.3.0'
gem 'mock_redis', '~> 0.14.0'
gem 'sidekiq-unique-jobs', '3.0.11' # sidekiq-unique-jobs > 3.0.11 broke spec
gem 'sidekiq-failures', '~> 0.4.3'
gem 'sinatra', '>= 1.3.0', :require => nil
gem 'whenever', '~> 0.9.4', :require => false

gem 'newrelic_rpm', '~> 4.2.0.334'
gem "airbrake", '~> 4.1.0'

gem 'feedjira', '~> 1.5.0'

group :development, :test do
  gem 'binding_of_caller'
  gem 'pry-rails'
  gem 'rspec-rails', '~> 3.0.0'
end

group :test do
  gem 'rspec-sidekiq', '~> 3.0.1'
  gem 'simplecov', '~> 0.7.1'
  gem 'rspec_junit_formatter', '~> 0.2.3'
end
