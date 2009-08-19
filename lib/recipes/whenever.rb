namespace :whenever do
  [:update_crontab, :write_crontab].each do |t|
    task t, :roles => :app do
      run "cd #{current_path} && PATH=#{path} whenever --#{t}"
    end
  end
end
