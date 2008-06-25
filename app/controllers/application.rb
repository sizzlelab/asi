# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.



class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '9c4bfc3f5c5b497cf9ce1b29fdea20f5'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password

  def session_user
    return Person.find_by_id(session["user"])
  end

  def session_client
    return Client.find_by_id(session["client"])
  end

end
