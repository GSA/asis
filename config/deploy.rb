# config valid for current version and patch releases of Capistrano
lock "~> 3.19.1"

set :application, "asis"
set :repo_url,    "https://github.com/GSA/asis.git"

set :branch, "staging"
# set :user, :search

# Set deploy directory
set :deploy_to, ENV.fetch('DEPLOYMENT_PATH')

# set :puma_user, fetch(:user)
# set :puma_service_unit_env_files, []
# set :puma_service_unit_env_vars, []

# set :systemctl_user, fetch(:user)
# set :puma_systemctl_user, :search

set :puma_bind, "tcp://0.0.0.0:5601"
set :puma_preload_app, false

# SSHKit.config.command_map[:bundle] = 'bin/bundle'

# set :rbenv_custom_path, "/usr"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, '.env'

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "vendor", "storage"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

# before 'deploy:finished', 'newrelic:notice_deployment'

# Systemd socket activation starts your app upon first request if it is not already running
# set :puma_enable_socket_service, true

# set :puma_user, fetch(:user)
# set :puma_role, :web
# set :puma_service_unit_env_files, []
# set :puma_service_unit_env_vars, []
