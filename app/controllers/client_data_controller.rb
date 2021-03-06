class ClientDataController < ApplicationController

  before_filter :ensure_person_login
  before_filter :ensure_client_login
  before_filter :authorize
  before_filter :get_or_create

  ##
  # access:: Self
  # return_code:: 200 - OK
  # description:: Gets every key-value pair that has been saved for this user by this application.
  def show
    render_json :entry => @set and return
  end

  ##
  # access:: Self
  # return_code:: 200 - OK
  # description:: Adds new key-value pairs about this user. Any previous data with the same key (or keys) is overwritten with the data provided.
  #
  # params::
  #   data::
  #     any_key:: any value
  #     any_other_key:: any other value
  def update
    @set.update_attributes({ :data => params[:data] })
    render_json :entry => @set and return
  end

  private

  def get_or_create
      @set = ClientDataSet.where(:client_id => @client.id, :person_id => @user.id).first ||
             ClientDataSet.new(:client => @client, :person => @user)
  end

  def authorize
    if @client.id != params[:app_id] || @user.guid != params[:user_id]
      render_json :status => :forbidden and return
    end
  end
end
