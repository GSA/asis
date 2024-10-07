# frozen_string_literal: true

require 'capistrano/setup'

require 'capistrano/deploy'

require 'capistrano/scm/git'
install_plugin Capistrano::SCM::Git

SSHKit.config.command_map[:bundle] = 'bin/bundle'

require "capistrano/rbenv"
require "capistrano/bundler"

require 'capistrano/puma'
require 'capistrano/sidekiq'
require 'capistrano/sidekiq/systemd'

install_plugin Capistrano::Puma, load_hooks: false
install_plugin Capistrano::Puma::Systemd

require 'whenever/capistrano'

Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }