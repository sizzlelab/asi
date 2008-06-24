class PseudoAuthenticationController < ApplicationController

  def login
    session[:user] = params[:user_id]
    session[:client] = params[:client_id]
  end

  def logout
    reset_session
  end

end
