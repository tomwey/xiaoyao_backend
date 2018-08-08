# config valid only for Capistrano 3.1
# lock '3.7.2'

set :application, 'xiaoyao_backend'
set :deploy_user, "root"

# set :scm, :git
set :repo_url, "git@github.com:tomwey/#{fetch(:application)}.git"

set :sidekiq_config, -> { File.join(shared_path, 'config', 'sidekiq.yml') }
set :pty,  false

set :rbenv_type, :user
set :rbenv_ruby, '2.3.1'
set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
set :rbenv_map_bins, %w{rake gem bundle ruby rails sidekiq sidekiqctl puma pumactl}

set :keep_releases, 5

set :linked_files, %w{config/database.yml config/config.yml config/redis.yml config/sidekiq.yml} # config/redis.yml

# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/uploads public/system}
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/uploads public/system}

# which config files should be copied by deploy:setup_config
# see documentation in lib/capistrano/tasks/setup_config.cap
# for details of operations
set(:config_files, %w(
  nginx.conf
  database.yml
  config.yml
  redis.yml
  log_rotation
  unicorn.rb
  unicorn_init.sh
  sidekiq.yml
))

# which config files should by made executable after copying
# by deploy:setup_config
set(:executable_config_files, %w(
  unicorn_init.sh
))

# files which need to be symlinked to other parts of the
# filesystem.

set(:symlinks, [
  {
    source: "nginx.conf",
    link: "/etc/nginx/sites-enabled/{{full_app_name}}"
  },
  {
    source: "unicorn_init.sh",
    link: "/etc/init.d/unicorn_{{full_app_name}}"
  },
  {
    source: "log_rotation",
   link: "/etc/logrotate.d/{{full_app_name}}"
  },
  # {
  #   source: "monit",
  #   link: "/etc/monit/conf.d/{{full_app_name}}.conf"
  # }
])

namespace :deploy do
  # make sure we're deploying what we think we're deploying
  before :deploy, "deploy:check_revision"
  
  # compile assets locally then rsync
  # after 'deploy:symlink:shared', 'deploy:compile_assets_locally'
  after :finishing, 'deploy:cleanup'
  
  # remove the default nginx configuration as it will tend
  # to conflict with our configs.
  before 'deploy:setup_config', 'nginx:remove_default_vhost'
  
  # reload nginx to it will pick up any modified vhosts from
  # setup_config
  after 'deploy:setup_config', 'nginx:reload'
  
  # Restart monit so it will pick up any monit configurations
  # we've added
  # 监控进程的时候才用得到
  # after 'deploy:setup_config', 'monit:restart'
  
  # As of Capistrano 3.1, the `deploy:restart` task is not called
  # automatically.
  # after 'deploy:publishing', 'deploy:restart'
  # after 'deploy:publishing', 'puma:restart'
end

# namespace :bower do
#   desc 'Install bower'
#   task :install do
#     on roles(:web) do
#       within release_path do
#         with rails_env: fetch(:rails_env) do
#           execute :rake, 'bower:install CI=true'
#         end
#       end
#     end
#   end
# end
# before 'deploy:compile_assets', 'bower:install'


#############################################################
#####################    以前旧的方式   #######################
#############################################################
# namespace :deploy do
#
#   %w[start stop restart].each do |command|
#     desc "#{command} unicorn server"
#     task command do
#       on roles(:app), in: :sequence, wait: 1 do
#         execute "/etc/init.d/unicorn_#{fetch(:application)} #{command}"
#       end
#     end
#   end
#
#   # task :setup_config do
#   #   put File.read("config/database.yml.example"), "#{shared_path}/config/database.yml"
#   #   put File.read("config/config.yml.example"), "#{shared_path}/config/config.yml"
#   # end
#
#   after :finishing, 'deploy:cleanup'
#   after :finishing, 'deploy:restart'
#
#   # before 'deploy:check:linked_files', 'deploy:setup_config'
# end
#
# namespace :remote_rake do
#   task :create do
#     run "cd #{deploy_to}/current; RAILS_ENV=production bundle exec rake db:create"
#   end
#   task :migrate do
#     run "cd #{deploy_to}/current; RAILS_ENV=production bundle exec rake db:migrate"
#   end
#   task :seed do
#     run "cd #{deploy_to}/current; RAILS_ENV=production bundle exec rake db:seed"
#   end
#   task :drop do
#     run "cd #{deploy_to}/current; RAILS_ENV=production bundle exec rake db:drop"
#   end
# end

