class SessionsController < ApplicationController

  before_filter :ensure_client_logout, :only => :create
  
  def get
    @session = @application_session
    if !@session
      render :status => :not_found and return
    end
  end
 
  def create
    @session = Session.new({ :username => params[:username], 
                             :password => params[:password], 
                             :client_name => params[:app_name], 
                             :client_password => params[:app_password] })

    
    if (params[:username] || params[:password])
        # If other is present, both need to be
        unless (params[:username] && params[:password])
          render :status => :bad_request, :json => "Both username and password are needed.".to_json
          return
        end
    end
    
    if @session.save
      if (! @session.person_match) && (params[:username] || params[:password])
        # inserted username, password -pair is not found in database
        @session.destroy

        render :status => :unauthorized, :json => "Password and username didn't match for any person.".to_json and return

      end
      session[:session_id] = @session.id
      render :status => :created, :json => { :user_id => @session.person_id,
                                             :app_id => @session.client_id }
    else

      render :status => :unauthorized, :json => @session.errors.full_messages.to_json and return

    end
  end
 
  def destroy
    render :status => :not_found and return unless @application_session
    @application_session.destroy
    session[:session_id] = @user = @client = nil
  end
  
end
