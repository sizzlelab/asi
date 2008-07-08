class ClientDataController < ApplicationController

  before_filter :ensure_person_login
  before_filter :authorize
  before_filter :get_or_create

  def show
    # Do nothing
  end

  def update
    params[:data].each { |key, value| @set.put(key,value) }
  end

  private
  def get_or_create
    begin
      @set = ClientDataSet.find(:first, :conditions => { :client_id => @client.id, :person_id => @user.id })
    rescue ActiveRecord::RecordNotFound
      @set = ClientDataSet.new(:client_id => @client.id, :person_id => @person.id)
    end
  end

  def authorize
    if @client.id != params[:user_id] || @user.id != params[:app_id]
      render :status => :forbidden and return
    end
  end 
end
