namespace :apache do
  task :restart do
    sudo "/etc/init.d/apache2 restart"
  end
end
