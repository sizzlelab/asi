# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'logging_helper'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  layout 'default'

  before_filter :maintain_session_and_user
  before_filter :log

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  #protect_from_forgery # :secret => '9c4bfc3f5c5b497cf9ce1b29fdea20f5'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password


  def index
  end

  def doc
    render :action => request.path[1..-1]
  end

  def ensure_person_login
    unless @user
      flash[:notice] = "Please login as a user to continue"
      head :status => :unauthorized and return
    end
  end
 
  def ensure_person_logout
    if @user
      flash[:notice] = "You must logout before you can login or register"
      head :status => :conflict and return
    end
  end
  
  def ensure_client_login
    unless @client
      flash[:notice] = "Please login as a client to continue"
      head :status => :unauthorized and return
    end
  end
 
  def ensure_client_logout
    if @client
      flash[:notice] = "You must logout client before you can login"
      render :status => :conflict and return
    end
  end
  
  def ensure_same_as_logged_person(target_person_id)
    return @user && target_person_id == @user.id
  end
  
  def log
    request.extend(LoggingHelper)
    logger.info(request.to_json({ :params => params, 
                                  :session => @application_session }))
  end

  protected
 
  def maintain_session_and_user
    if session[:session_id]
      if @application_session = Session.find_by_id(session[:session_id])
        begin #Strange rescue solution is because request.path_info acts strangely in tests
          path = request.path_info
        rescue NoMethodError => e
          path = "running/tests/no/path/available"
        end
        @application_session.update_attributes(:ip_address => request.remote_addr, :path => path)
        @user = @application_session.person
        @client = @application_session.client
      else
        session[:session_id] = nil
        redirect_to(root_url)
      end
    else
      #logger.debug "NO SESSION:" + session[:session_id]
    end
    
  end
end
