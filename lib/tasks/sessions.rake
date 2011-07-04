namespace :sessions do
  
  desc "Clears old sessions from the database. The time limit can be set in config.yml"
  task :cleanup => :environment  do
    Session.cleanup
  end
end

