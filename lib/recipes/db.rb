namespace :db do
  task :backup do
    run "cd #{current_path} && rake db:backup RAILS_ENV=#{rails_env} MAX=10 DIR=/home/#{user}/backup"
  end
end
