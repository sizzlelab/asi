
class SessionsController < ApplicationController
  before_filter :ensure_client_login, :only => :destroy
  before_filter :ensure_client_logout, :only =>  :create
 
  def create
    @session = Session.new({ :username => params[:username], :password => params[:password], :client_name => params[:client_name], :client_password => params[:client_password]})
    
    if @session.save
      if (! @session.person_match) && (params[:username] || params[:password])
        # Person did not match, but tried logging in a person
        @session.destroy
        render :status => :unauthorized and return
        #TODO return more information about that user part was wrong
      end
      session[:session_id] = @session.id
      render :status => :ok #TODO decide if this should be 201 instead?
    else
      render :status => :unauthorized and return
      #TODO return more information about what failed? user or client or both?
    end
  end
 
  def destroy
    Session.destroy(@application_session)
    session[:session_id] = @user = @client = nil
    render :status  => 200 and return
  end
end
