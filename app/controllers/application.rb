# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'logging_helper'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  layout 'default'

  before_filter :maintain_session_and_user
  before_filter :log
  
  after_filter :set_correct_content_type

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  #protect_from_forgery # :secret => '9c4bfc3f5c5b497cf9ce1b29fdea20f5'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password

  DEFAULT_AVATAR_IMAGES = {
    "ossi" => {
      "full" => "cos_avatar_80_80.jpg",
      "large_thumb" => "cos_avatar_80_80.jpg",
      "small_thumb" => "cos_avatar_50_50.jpg"
    },
    "kassi" => {
      "full" => "cos_avatar_80_80.jpg",
      "large_thumb" => "cos_avatar_80_80.jpg",
      "small_thumb" => "cos_avatar_50_50.jpg"
    }
  }

  def doc
    render :action => request.path[1..-1]
  end

  def ensure_person_login
    unless @user
      head :status => :unauthorized, :json => "Please login as a user to continue".to_json and return
    end
  end
 
  def ensure_person_logout
    if @user
      head :status => :conflict, :json => "You must logout before you can login or register".to_json and return
    end
  end
  
  def ensure_client_login
    unless @client
      head :status => :unauthorized, :json => "Please login as a client to continue".to_json and return
    end
  end
 
  def ensure_client_logout
    if @client
      render :status => :conflict, :json => "You must logout client before you can login".to_json and return
    end
  end
  
  def ensure_same_as_logged_person(target_person_id)
    return @user && target_person_id == @user.id
  end
  
  def log
    request.extend(LoggingHelper)
    logger.info("  Session: " + request.to_json({ :session => @application_session }))
    logger.info("  Headers: " + request.headers.except("RAW_POST_DATA").to_json)
    logger.info { "Session DB id:  #{session[:session_id]}" }
  end
  
  def set_correct_content_type
    if params["format"] 
      response.content_type = Mime::Type.lookup_by_extension(params["format"].to_s).to_s 
    end
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
        render :status => :unauthorized and return
      end
    else
      #logger.debug "NO SESSION:" + session[:session_id]
    end
    
  end
end
