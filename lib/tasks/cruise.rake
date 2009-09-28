desc 'Used for Cruise Control Continuous Integration.'
task :cruise => ['db:migrate'] do
  system("rake db:migrate db:fixtures:load RAILS_ENV=test")
  system("rake thinking_sphinx:configure thinking_sphinx:index thinking_sphinx:rebuild RAILS_ENV=test")
  system("script/rapidoc/generate")
  Rake::Task["test"].invoke rescue got_error = true
  system("rake thinking_sphinx:stop RAILS_ENV=test")
end
