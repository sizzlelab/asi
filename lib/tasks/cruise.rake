desc 'Used for Cruise Control Continuous Integration.'
task :cruise => ['db:migrate'] do
  system("rake db:migrate db:fixtures:load RAILS_ENV=test")
  system("rake ts:configure ts:index ts:rebuild RAILS_ENV=test")
  Rake::Task["test"].invoke rescue got_error = true
  system("rake ts:stop RAILS_ENV=test")
end
