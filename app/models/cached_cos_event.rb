class CachedCosEvent < ActiveRecord::Base

  def CachedCosEvent.upload_all
    if CachedCosEvent.count > 0
      logger.info "Uploading #{CachedCosEvent.count} events to Ressi at #{Time.now}.\n"

      CachedCosEvent.all.each do |event|
        begin
          event.upload
        rescue ActiveResource::ServerError => e
          logger.debug e
          event.destroy # Assume event was erroneus and drop
        end
        event.destroy
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
                              :headers =>        headers
                            })

    self.destroy if event.valid?
  end
end
