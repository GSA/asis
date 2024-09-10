# config valid for current version and patch releases of Capistrano
lock "~> 3.19.1"

set :application,     'asis'
set :branch,          'staging'
set :bundle_roles,    :all
set :deploy_to,       ENV.fetch('DEPLOYMENT_PATH')
set :format,          :pretty
set :puma_access_log, "#{release_path}/log/puma.access.log"
set :puma_bind,       'tcp://0.0.0.0:3300'
set :puma_error_log,  "#{release_path}/log/puma.error.log"
set :rails_env,       'production'
set :rbenv_type,      :user
set :repo_url,        'https://github.com/GSA/asis.git'
set :user,            ENV.fetch('SERVER_DEPLOYMENT_USER', 'search')
set :whenever_roles,  :cron

append :linked_files, '.env'
append :linked_dirs,  'log', 'tmp'

role :app,  JSON.parse(ENV.fetch('API_SERVER_ADDRESSES', '[]')),  user: ENV['SERVER_DEPLOYMENT_USER']
role :cron, JSON.parse(ENV.fetch('CRON_SERVER_ADDRESSES', '[]')), user: ENV['SERVER_DEPLOYMENT_USER']
role :db,   JSON.parse(ENV.fetch('API_SERVER_ADDRESSES', '[]')),  user: ENV['SERVER_DEPLOYMENT_USER']
role :web,  JSON.parse(ENV.fetch('API_SERVER_ADDRESSES', '[]')),  user: ENV['SERVER_DEPLOYMENT_USER']

set :ssh_options, {
  auth_methods:  %w(publickey),
  forward_agent: false,
  keys:          [ENV['SSH_KEY_PATH']],
  user:          ENV['SERVER_DEPLOYMENT_USER']
}
