# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.



class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  layout 'default'

  before_filter :maintain_session_and_user

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '9c4bfc3f5c5b497cf9ce1b29fdea20f5'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password


  def index
  end

# FROM PSEUDO AUTHENTICATION
  def session_client
    return Client.find_by_id(session["client"])
  end

# FROM AUTHENTICATION MODULE

  def ensure_login
    unless @user
      flash[:notice] = "Please login to continue"
      #redirect_to(new_session_path)
      #TODO better option for redirection that was used in original AUTH module
    end
  end
 
  def ensure_logout
    if @user
      flash[:notice] = "You must logout before you can login or register"
      redirect_to(root_url)
    end
  end
 
  private
 
  def maintain_session_and_user
    if session[:id]
      if @application_session = Session.find_by_id(session[:id])
        begin #Strange rescue-solution is because request.path_info acts strangely in tests
          path = request.path_info
        rescue NoMethodError => e
          path = "running/tests/no/path/available"
        end
        @application_session.update_attributes(:ip_address => request.remote_addr, :path => path)
        @user = @application_session.person
      else
        session[:id] = nil
        redirect_to(root_url)
      end
    end
  end

end
