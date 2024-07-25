# Load DSL and set up stages
require "capistrano/setup"

require "capistrano/deploy"

require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

require "capistrano/rbenv"
set :rbenv_ruby, '3.1.4'
set :rbenv_type, :user

SSHKit.config.command_map[:bundle] = 'bin/bundle'

require "capistrano/bundler"
require 'capistrano/newrelic'

require 'capistrano/puma'
install_plugin Capistrano::Puma, load_hooks: false
install_plugin Capistrano::Puma::Systemd

# require 'capistrano/sidekiq'
# install_plugin Capistrano::Sidekiq
# install_plugin Capistrano::Sidekiq::Systemd

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }
