
class SessionsController < ApplicationController
  before_filter :ensure_login, :only => :destroy
  before_filter :ensure_logout, :only => [:new, :create]
   
  def create
    @session = Session.new({ :username => params[:username], :password => params[:password], :client_name => params[:client_name], :client_password => params[:client_password]})
    if @session.save
      session[:session_id] = @session.id
      session["client"] = params[:client_id]   # TODO FROM PSEUDO AUTH check if needed
      #redirect_to(root_url)
      render :status => :ok   #TODO decide if this should be 201 instead?
    else
      #render(:action => 'new')
      #logger.debug "Returned unauthorized for USER: #{@session.inspect}, PASSU: #{@session}"
      render :status => :unauthorized
    end
  end
 
  def destroy
    Session.destroy(@application_session)
    session[:session_id] = @user = nil
    session["client"] = nil
    render :status  => 200 and return
  end
end
