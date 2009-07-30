class ClientDataController < ApplicationController

  before_filter :ensure_person_login
  before_filter :authorize
  before_filter :get_or_create

  def show
    # Do nothing
    render_json :entry => @set and return
  end

  def update
    @set.update_attributes({ :data => params[:data] })
    render_json :entry => @set and return
  end

  private
  def get_or_create
    begin
      @set = ClientDataSet.find(:first, :conditions => { :client_id => @client.id, :person_id => @user.guid })
    rescue ActiveRecord::RecordNotFound
      @set = ClientDataSet.new(:client_id => @client.id, :person_id => @person.id)
    end
  end

  def authorize
    if @client.id != params[:app_id] || @user.guid != params[:user_id]
      render :status => :forbidden and return
    end
  end
end
