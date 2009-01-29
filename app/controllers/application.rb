# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'logging_helper'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  layout 'default'

  before_filter :maintain_session_and_user
  
  after_filter :log
  after_filter :set_correct_content_type

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  #protect_from_forgery # :secret => '9c4bfc3f5c5b497cf9ce1b29fdea20f5'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password

  DEFAULT_AVATAR_IMAGES = {
    "cos" => {
      "full" => "cos_avatar_80_80.jpg",
      "large_thumb" => "kassi_avatar.png",
      "small_thumb" => "kassi_avatar_small.png"
    },
    "ossi" => {
      "full" => "cos_avatar_80_80.jpg",
      "large_thumb" => "cos_avatar_80_80.jpg",
      "small_thumb" => "cos_avatar_50_50.jpg"
    },
    "kassi" => {
      "full" => "kassi_avatar.png",
      "large_thumb" => "kassi_avatar.png",
      "small_thumb" => "kassi_avatar_small.png"
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
    
    # Saving the log data also to Ressi
    if RESSI_URL
      cos_event = CosEvent.create({
        :user_id =>        @user ? @user.id : nil,
        :application_id => @client ? @client.id : nil, 
        :cos_session_id => @_session.session_id, 
        :ip_address =>     request.remote_ip, 
        :action =>         controller_class_name + "\#" + action_name, 
        :parameters =>     respond_to?(:filter_parameters) ? filter_parameters(params).to_json : params.to_json, # from base.rb in action_controller 
        :return_value =>   @_response.headers['Status'], 
        :headers =>        request.headers.except("RAW_POST_DATA").to_json
        })
    end if
    
    logger.info { "Session DB id:  #{session[:session_id]}   Ressi: #{RESSI_URL ? cos_event.valid? : nil}" }
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
