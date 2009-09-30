namespace :rapidoc do
  task :generate, :roles => :app do
    run "#{current_path}/script/rapidoc/generate"
  end
end
