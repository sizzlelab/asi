class CachedCosEvent < ActiveRecord::Base
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
