# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Learn more: http://github.com/javan/whenever


# use this if you are proxying through apache instead of running
# ASI with mod_rails (passenger)

#every 1.hour do
#  command 'wget http://localhost:3000/system/reindex'
#end

#every 1.day, :at => '3am' do
#  command 'wget http://localhost:3000/system/upload'
#  command 'wget http://localhost:3000/system/clean_sessions'
#end



# use this if you are running ASI with mod_rails (passenger)

ASI_ROOT = '/opt/asi/current'

every 1.hour do
#  command 'cd '+ASI_ROOT+'; rake thinking_sphinx:rebuild;'
  rake "thinking_sphinx:rebuild"
end

every 1.day, :at => '3am' do
  rake "ressi:upload"
  rake "tmp:sessions:clear"
  rake "db:sessions:clear"
end
