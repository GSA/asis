# config valid for current version and patch releases of Capistrano
lock "~> 3.19.1"

set :application, "asis"
set :repo_url,    "git@github.com:GSA/asis.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Set deploy directory
set :deploy_to, ENV.fetch('DEPLOYMENT_PATH')

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml", 'config/master.key'

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

before :updated, :symlink_puma_service

task :symlink_puma_service do
  on roles(:app) do
    execute :ln, "-s", "#{release_path}/puma.service", "/etc/systemd/system/puma.service"
  end
end

before 'deploy:finished', 'newrelic:notice_deployment'
