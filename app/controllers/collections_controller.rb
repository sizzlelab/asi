class CollectionsController < ApplicationController

  before_filter :verify_client

  before_filter :get_or_not_found, :except => [ :create, :index ]

  verify :method => :post, 
         :only => :create, 
         :render => { :status => :method_not_allowed },
         :add_headers => { 'Allow' => 'POST' }

  verify :method => :delete,
         :only => [ :delete ],
         :render => { :status => :method_not_allowed },
         :add_headers => { 'Allow' => 'DELETE' }

  verify :method => :put,
         :only => [ :update ],
         :render => { :status => :method_not_allowed },
         :add_headers => { 'Allow' => 'PUT' }

  def index
    @collections = Collection.find(:all, :conditions => { :client_id => @client.id })
    @collections.reject! { |item| ! item.read?(@user, @client) }
  end

  def show
    if @collection.client != @client or ! @collection.read?(@user, @client)
      @collection = nil
      render :status => :forbidden
    end
  end

  def create
    @collection = Collection.new(:read_only => params["read_only"],
                                 :indestructible => params["indestructible"],
                                 :metadata => params[:metadata])

    if @user and params['owner']
      if @collection.indestructible
        render :status => :bad_request, :json => "Cannot set both: owner and indestructible" and return
      elsif params['owner'] != @user.id
        render :status => :bad_request, :json => "Owner cannot be different than logged in user." and return
      else
        @collection.owner = @user
      end
    end
    
    @collection.client = @client
    @collection.save
    render :status => :created
  end

  def update
    render :status => :forbidden and return unless @collection.write?(@user, @client)
    @collection.update_attributes({:metadata  => params[:metadata ]})
    @collection.update_attributes({:read_only => params[:read_only]}) if params[:read_only]
  end

  def delete
    if ! @collection.delete?(@user, @client)      
      render :status => :forbidden and return
    end
    @collection.destroy
  end

  def add
    if ! @collection.write?(@user, @client)
      render :status => :forbidden and return
    end
    head :status => :bad_request and return unless @collection.create_item(params, @user)
    @item = @collection.items[-1]
  end
  
  private
  
  def verify_client
    if @client == nil or params["app_id"].to_s != @client.id.to_s
      render :status => :forbidden and return
    end
  end

  def get_or_not_found
    begin
      @collection = Collection.find(params['id'])
    rescue ActiveRecord::RecordNotFound
      head :status => :not_found and return
    end
  end
end
