#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "production"

require File.dirname(__FILE__) + "/../../config/environment"
require 'json'

$running = true
Signal.trap("TERM") do 
  $running = false
end

logger = ActionController::Base.logger

logger.info "Ressi logging daemon running..."

while($running) do
  if Time.now.hour == RESSI_UPLOAD_HOUR and CachedCosEvent.count > 0
    logger.info "Uploading #{CachedCosEvent.count} events to Ressi at #{Time.now}.\n"
    CachedCosEvent.all.each { |e| e.upload }
    logger.info "Uploading #{CachedCosEvent.count} events to Ressi finished at #{Time.now}.\n"
  end

  s = 3600
  logger.info "Ressi logging daemon sleeping for #{s} seconds...\n"
  sleep s
end
