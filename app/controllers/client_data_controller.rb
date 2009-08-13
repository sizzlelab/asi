class ClientDataController < ApplicationController

  before_filter :ensure_person_login
  before_filter :ensure_client_login
  before_filter :authorize
  before_filter :get_or_create

  def show
    render_json :entry => @set and return
  end

  def update
    @set.update_attributes({ :data => params[:data] })
    render_json :entry => @set and return
  end

  private

  def get_or_create
      @set = ClientDataSet.find(:first, :conditions => { :client_id => @client.id, :person_id => @user.id }) ||
             ClientDataSet.new(:client => @client, :person => @user)
  end

  def authorize
    if @client.id != params[:app_id] || @user.guid != params[:user_id]
      render_json :status => :forbidden and return
    end
  end
end
