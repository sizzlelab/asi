#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "production"

require File.dirname(__FILE__) + "/../../config/environment"

$running = true
Signal.trap("TERM") do
  $running = false
end

while($running) do
  system("rake ts:rebuild RAILS_ENV='production'")
  sleep 3600
end
