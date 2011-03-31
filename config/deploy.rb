require 'bundler/capistrano'
set :application, "cos"


set :scm, :git
set :repository, "git://github.com/sizzlelab/asi.git"
set :deploy_via, :remote_cache

if ENV['DEPLOY_ENV'] == "beta" ||  ENV['DEPLOY_ENV'] == "alpha" 
  set :deploy_to, "/var/datat/cos/common-services"
  set :server_name, ENV['DEPLOY_ENV']
  set :host, "#{ENV['DEPLOY_ENV']}.sizl.org"
  set :user, "cos"
elsif ENV['DEPLOY_ENV'] == "icsi"
  set :deploy_to, "/opt/asi"
  set :server_name, "icsi"
  set :host, "sizl.icsi.berkeley.edu"
  set :user, ENV['USER']
else
  set :server_name, "localhost"
  set :host, "localhost"
end

role :app, "#{user}@#{host}"
role :db, "#{user}@#{host}", :primary => true


set :rails_env, :production

if ENV['DEPLOY_ENV'] == "icsi"
  set :path, "$PATH:/usr/local/bin"
else
  set :path, "$PATH:/var/lib/gems/1.8/bin"
end

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

namespace :deploy do

  task :setup do
    run "mkdir -p #{deploy_to}/releases"
    %w(db/sphinx tmp/pids log config).each do |dir|
      run "mkdir -p #{shared_path}/#{dir}"
    end
  end

  task :before_cold do
    run "killall searchd" rescue nil
  end

  task :before_update_code do
    thinking_sphinx.stop rescue nil
  end

  task :after_update_code do
    deploy.symlink_nonscm_configs
  end

  before "deploy:migrate", "db:backup"

  task :symlink_nonscm_configs do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/session_secret #{release_path}/config/session_secret"
    run "ln -nfs #{shared_path}/config/config.yml #{release_path}/config/config.yml"
  end

  task :after_symlink do
    run "chmod -R o+rx #{current_path}"
    run "cp #{current_path}/REVISION #{current_path}/app/views/layouts/_revision.html.erb"
    run "date > #{current_path}/app/views/layouts/_build_date.html.erb"
  end
  
  task :before_start do
    run "chmod -R o+rx #{current_path}"
    symlink_sphinx_indexes
    thinking_sphinx.configure
    thinking_sphinx.index
    thinking_sphinx.start
  end

  after %w(deploy deploy:migrations deploy:cold), "deploy:finalize"

  before "deploy:restart", "deploy:sphinx"
  before "deploy:sphinx", "deploy:rapidocs"

  task :rapidocs do
    #required for the APIFactory in rapidoc generation to work
    #run "cd #{current_path} && rake db:migrate RAILS_ENV=development"
    run "cd #{current_path}"
    rapidoc.generate
  end

  task :sphinx do
    symlink_sphinx_indexes
    thinking_sphinx.configure
    thinking_sphinx.start
  end

  task :finalize do
    whenever.write_crontab
  end

  desc "Link up Sphinx's indexes."
  task :symlink_sphinx_indexes, :roles => [:app] do
    run "ln -nfs #{shared_path}/db/sphinx #{current_path}/db/sphinx"
  end

end


Dir[File.join(File.dirname(__FILE__), '..', 'vendor', 'gems', 'hoptoad_notifier-*')].each do |vendored_notifier|
  $: << File.join(vendored_notifier, 'lib')
end

require 'hoptoad_notifier/capistrano'
