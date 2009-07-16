desc 'Used for Cruise Control Continuous Integration.'
task :cruise => ['db:migrate'] do
  system("rake ts:rebuild RAILS_ENV=test")
  Rake::Task["test"].invoke rescue got_error = true
  system("rake ts:stop RAILS_ENV=test")
end
