namespace :whenever do
  task :update_crontab, :roles => :app do
    run "cd #{current_path} && PATH=#{path} whenever --update-crontab"
  end
end
