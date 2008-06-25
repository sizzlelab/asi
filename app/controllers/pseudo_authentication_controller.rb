class PseudoAuthenticationController < ApplicationController

  def login
    session["user"] = params[:user_id]
    session["client"] = params[:client_id]
  end

  def logout
    reset_session
  end

  def easy_login
    session[:user] = Person.find(:first).id
    session[:client] = Client.find(:first).id
  end

  def view_session
    @user = session[:user]
  end

end
