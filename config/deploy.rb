set :application, "cos"
set :repository_root, "svn+ssh://cos@alpha.sizl.org/svn/common-services"

set :user, "cos"
set :host, "localhost"

if ENV['DEPLOY_ENV'] == "alpha"
  set :server_config, "alpha"
elsif ENV['DEPLOY_ENV'] == "beta"
  set :server_config, "beta"
  set :host, "beta.sizl.org"
else
  set :server_config, "localhost"
  set :host, "localhost"
end


role :app, "#{user}@#{host}"
role :db, "#{user}@#{host}", :primary => true


set :repository,  "#{repository_root}/trunk"


set :deploy_to, "/var/datat/cos/common-services"
set :mongrel_conf, "#{current_path}/config/mongrel_cluster.yml"
set :rails_env, :production

set :path, "$PATH:/var/lib/gems/1.8/bin"
set :mongrel_conf, "#{shared_path}/config/mongrel_cluster.yml"

namespace :deploy do

  [ :stop, :start, :restart ].each do |t|
    task t, :roles => :app do
      deploy.mongrel.send(t)
    end
  end

  task :before_update_code do
    thinking_sphinx.stop rescue nil
  end

  task :after_update_code do
  end

  before "deploy:migrate", "db:backup"
  after "deploy:update", "deploy:sphinx"

  task :sphinx do
    symlink_sphinx_indexes
    thinking_sphinx.configure
    thinking_sphinx.start
  end

  task :after_symlink do
    run "rm -rf #{current_path}/log && ln -s #{shared_path}/log #{current_path}/log"
    run "mv #{current_path}/REVISION #{current_path}/app/views/layouts/_revision.html.erb"
    run "date > #{current_path}/app/views/layouts/_build_date.html.erb"
    rapidoc.generate
    run "cd #{current_path} && cp config/#{server_config}.rb config/initializers"
  end

  after %w(deploy deploy:migrations deploy:cold), "deploy:finalize"

  task :finalize do
    whenever.write_crontab
    apache.restart
  end

  desc "Link up Sphinx's indexes."
  task :symlink_sphinx_indexes, :roles => [:app] do
    run "ln -nfs #{shared_path}/db/sphinx #{current_path}/db/sphinx"
  end

end
