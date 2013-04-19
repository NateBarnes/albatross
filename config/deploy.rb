role :app, "ec2-50-19-182-192.compute-1.amazonaws.com"

set :application, "albatross"
set :copy_strategy, :export
set :deploy_to, "/var/www"
set :deploy_via, :copy
set :repository,  "git@github.com:NateBarnes/albatross.git"
set :user, 'ubuntu'

after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end
