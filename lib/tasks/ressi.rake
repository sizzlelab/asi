namespace :ressi do
  desc "Uploads logging data to Ressi"
  task :upload => :environment do
    puts "Uploading #{CachedCosEvent.count} events to Ressi"
    CachedCosEvent.upload_all
  end
end
