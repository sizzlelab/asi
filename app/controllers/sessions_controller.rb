
class SessionsController < ApplicationController
  before_filter :ensure_login, :only => :destroy
  before_filter :ensure_logout, :only => [:new, :create]
 
  def index
    redirect_to(new_session_path)
  end
 
  def new
    @session = Session.new
  end
 
  def create
    @session = Session.new(params[:session])
    if @session.save
      session[:id] = @session.id
      session["client"] = params[:client_id]   # TODO FROM PSEUDO AUTH check if needed
      flash[:notice] = "Hello #{@session.person.username}, you are now logged in"
      #redirect_to(root_url)
      render :status  => 200   #TODO decide if this should be 201 instead?
    else
      #render(:action => 'new')
      logger.debug "USER: #{@session.inspect}, PASSU: #{@session}"
      render :status => 401 #Unauthorized
    end
  end
 
  def destroy
    Session.destroy(@application_session)
    session[:id] = @user = nil
    session["client"] = nil
    #flash[:notice] = "You are now logged out"
    #redirect_to(root_url)
    render :status  => 200 and return
  end
end
