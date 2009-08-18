set :application, "cos"
set :repository_root, "svn+ssh://cos@alpha.sizl.org/svn/common-services"
set :repository,  "#{repository_root}/trunk"

set :server_config, "alpha"

set :deploy_to, "/var/datat/cos/common-services"
set :mongrel_conf, "#{current_path}/config/mongrel_cluster.yml"
set :rails_env, :production
set :user, "cos"

set :path, "$PATH:/var/lib/gems/1.8/bin"
set :mongrel_conf, "#{shared_path}/config/mongrel_cluster.yml"

role :app, "#{user}@localhost"
role :db, "#{user}@localhost", :primary => true

namespace :deploy do

  [ :stop, :start, :restart ].each do |t|
    task t, :roles => :app do
      deploy.mongrel.send(t)
    end
  end

  task :after_update do
    run "mv #{current_path}/REVISION #{current_path}/app/views/layouts/_revision.html.erb"
    run "date > #{current_path}/app/views/layouts/_build_date.html.erb"
    rapidoc.generate
  end

  after "deploy", "deploy:finalize"
  after "deploy:cold", "deploy:finalize"

  task :finalize do
    run "cd #{current_path} && cp config/environments/#{server_config}.rb config/environments/server.rb"
    whenever.update_crontab
    sudo "/etc/init.d/apache2 restart"
  end

  task :before_update do
    thinking_sphinx.stop rescue nil
  end

  task :after_update do
    symlink_sphinx_indexes
    thinking_sphinx.configure
    thinking_sphinx.start
  end

  desc "Link up Sphinx's indexes."
  task :symlink_sphinx_indexes, :roles => [:app] do
    run "ln -nfs #{shared_path}/db/sphinx #{current_path}/db/sphinx"
  end

end
