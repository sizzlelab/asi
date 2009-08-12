# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Learn more: http://github.com/javan/whenever

every 1.hour do
  command 'wget http://localhost:3000/system/upload'
end

every 1.day, :at => '3am' do
  command 'wget http://localhost:3000/system/reindex'
  command 'wget http://localhost:3000/system/clean_sessions'
end
