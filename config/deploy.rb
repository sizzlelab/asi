set :application, "cos"
set :user, "cos"

set :repository, "svn+ssh://#{user}@alpha.sizl.org/svn/common-services/trunk"

if ENV['DEPLOY_ENV']
  set :server_name, ENV['DEPLOY_ENV']
  set :host, "#{ENV['DEPLOY_ENV']}.sizl.org"
else
  set :server_name, "localhost"
  set :host, "localhost"
end

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

  task :before_update_code do
    thinking_sphinx.stop rescue nil
  end

  before "deploy:migrate", "db:backup"

  task :after_symlink do
    run "mv #{current_path}/REVISION #{current_path}/app/views/layouts/_revision.html.erb"
    run "date > #{current_path}/app/views/layouts/_build_date.html.erb"
    rapidoc.generate
    run "cd #{current_path} && cp config/#{server_name}.rb config/initializers"
  end

  task :before_start do
    mongrel.configure
    symlink_sphinx_indexes
    thinking_sphinx.configure
    thinking_sphinx.index
    thinking_sphinx.start
  end

  before "deploy:restart", "deploy:sphinx"

  task :sphinx do
    symlink_sphinx_indexes
    thinking_sphinx.configure
    thinking_sphinx.start
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

  [ :stop, :start, :restart ].each do |t|
    task t, :roles => :app do
      mongrel.send(t)
    end
  end

end
