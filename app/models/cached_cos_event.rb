# == Schema Information
#
# Table name: cached_cos_events
#
#  id                :integer(4)      not null, primary key
#  user_id           :string(255)
#  application_id    :string(255)
#  cos_session_id    :string(255)
#  ip_address        :string(255)
#  action            :string(255)
#  parameters        :string(255)
#  return_value      :string(255)
#  headers           :text
#  created_at        :datetime
#  updated_at        :datetime
#  semantic_event_id :string(255)
#
require 'timeout'

class CachedCosEvent < ActiveRecord::Base

  def CachedCosEvent.upload_all
    if CachedCosEvent.count > 0
      logger.info "Uploading #{CachedCosEvent.count} events to Ressi at #{Time.now}.\n"

      CachedCosEvent.find_in_batches(:batch_size => 1000) do |events|
        events.each_with_index do |event, i|
          logger.info i if i % 1000 == 0
          tries = 0
          begin
            tries += 1
            event.upload
            event.destroy
          rescue => e
            if tries < 5
              logger.info "Retrying..."
              retry
            end
            raise e
          end
        end
      end
      logger.info "Ressi upload finished at #{Time.now}.\n"
    end
  end

  def upload

    event = CosEvent.create({
                              :user_id =>        user_id,
                              :application_id => application_id,
                              :cos_session_id => cos_session_id,
                              :ip_address =>     ip_address,
                              :action =>         action,
                              :parameters =>     parameters,
                              :return_value =>   return_value,
                              :headers =>        headers,
                              :semantic_event_id => semantic_event_id
                            })
  end
end
