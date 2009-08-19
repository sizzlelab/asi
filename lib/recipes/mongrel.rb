namespace :mongrel do
  [ :stop, :start, :restart ].each do |t|
    desc "#{t.to_s.capitalize} the mongrel appserver"
    task t, :roles => :app do
      run "PATH=#{path} mongrel_rails cluster::#{t.to_s} -C #{mongrel_conf}"
    end
  end

  task :configure, :roles => :app do
    run "PATH=#{path} mongrel_rails cluster::configure -e #{rails_env} -p 3000 -N 3 -c #{current_path} -C #{mongrel_conf} -P #{shared_path}/tmp/pids -a 127.0.0.1"
  end
end
