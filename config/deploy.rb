set :application, "cos"
set :user, "cos"

set :repository, "http://svn.github.com/sizzlelab/asi.git"

if ENV['DEPLOY_ENV']
  set :server_name, ENV['DEPLOY_ENV']
  set :host, "#{ENV['DEPLOY_ENV']}.sizl.org"
else
  set :server_name, "localhost"
  set :host, "localhost"
end

mongrel_cluster_size = {
  "alpha" => 7,
  "beta" => 13,
  "localhost" => 1
}

set :mongrel_cluster_size, mongrel_cluster_size[server_name]

role :app, "#{user}@#{host}"
role :db, "#{user}@#{host}", :primary => true

set :deploy_to, "/var/datat/cos/common-services"
set :mongrel_conf, "#{current_path}/config/mongrel_cluster.yml"
set :rails_env, :production

set :path, "$PATH:/var/lib/gems/1.8/bin"
set :mongrel_conf, "#{shared_path}/config/mongrel_cluster.yml"

namespace :deploy do

  task :setup do
    run "mkdir -p #{deploy_to}/releases"
    %w(db/sphinx tmp/pids log config).each do |dir|
      run "mkdir -p #{shared_path}/#{dir}"
    end
  end

  task :before_cold do
    run "killall mongrel_rails" rescue nil
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
    run "mv #{current_path}/REVISION #{current_path}/app/views/layouts/_revision.html.erb"
    run "date > #{current_path}/app/views/layouts/_build_date.html.erb"
    run "cd #{current_path} && cp config/#{server_name}.rb config/initializers"
  end
  
  task :before_start do
    mongrel.configure
    symlink_sphinx_indexes
    thinking_sphinx.configure
    thinking_sphinx.index
    thinking_sphinx.start
  end

  after %w(deploy deploy:migrations deploy:cold), "deploy:finalize"

  before "deploy:restart", "deploy:sphinx"
  before "deploy:sphinx", "deploy:rapidocs"

  task :rapidocs do
    #required for the Factory in rapidoc generation to work
    run "cd #{current_path} && rake db:migrate RAILS_ENV=development"
    rapidoc.generate
  end

  task :sphinx do
    symlink_sphinx_indexes
    thinking_sphinx.configure
    thinking_sphinx.start
  end

  task :finalize do
    whenever.write_crontab
    apache.restart
  end

  desc "Link up Sphinx's indexes."
  task :symlink_sphinx_indexes, :roles => [:app] do
    run "ln -nfs #{shared_path}/db/sphinx #{current_path}/db/sphinx"
  end

  [ :stop, :start, :restart ].each do |t|
    task t, :roles => :app do
      mongrel.send(t)
    end
  end

end
