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
    
    if @session.save
      if (! @session.person_match) && (params[:username] || params[:password])
        # Person did not match, but tried logging in a person
        @session.destroy
        render :status => :unauthorized and return
        #TODO return more information about that user part was wrong
      end
      session[:session_id] = @session.id
      render :status => :created, :json => { :user_id => @session.person_id,
                                             :app_id => @session.client_id }
    else
      render :status => :unauthorized and return
      #TODO return more information about what failed? user or client or both?
    end
  end
 
  def destroy
    render :status => :not_found and return unless @application_session
    @application_session.destroy
    session[:session_id] = @user = @client = nil
  end
end
