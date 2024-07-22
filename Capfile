# Load DSL and set up stages
require "capistrano/setup"
require "capistrano/deploy"

require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

require "capistrano/rbenv"
require "capistrano/bundler"
require "capistrano/rails/migrations"
require 'capistrano/newrelic'

require 'capistrano/sidekiq'
install_plugin Capistrano::Sidekiq
install_plugin Capistrano::Sidekiq::Systemd

require 'capistrano/puma'
install_plugin Capistrano::Puma
install_plugin Capistrano::Puma::Systemd

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }
