namespace :thinking_sphinx do
  [ :configure, :index, :start, :stop, :restart ].each do |t|
    task t, :roles => :app do
      run "cd #{current_path}; rake thinking_sphinx:#{t} --trace RAILS_ENV=#{rails_env}"
    end
  end
end
