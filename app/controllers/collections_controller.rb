class CollectionsController < ApplicationController

  before_filter :verify_client

  before_filter :get_or_not_found, :except => [ :create, :index, :delete_item ]

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
    conditions = { :client_id => @client.id }
    if params["tags"]
      conditions.merge!({:tags => params["tags"]})
    end
    
    @collections = Collection.find(:all, :conditions => conditions, :order => 'updated_at DESC' )
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
                                 :tags => params["tags"],
                                 :metadata => params[:metadata],
                                 :title => params["title"] )

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
    @collection.update_attributes({:title => params[:title]}) if params[:title]
    @collection.update_attributes({:tags => params[:tags]}) if params[:tags]
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
    head :status => :bad_request and return unless @collection.create_item(params, @user, @client)
    @item = @collection.items[-1]
  end
  
  def delete_item
    item_id = params["item_id"]
    
    item = TextItem.find_by_id(item_id)
    item = Image.find_by_id(item_id) if item.nil?
    item = Collection.find_by_id(item_id) if item.nil?
    render :status => :not_found, :json  => {:error => "Could not find the item with id #{item_id}"}.to_json and return if item.nil?
    
    if item.class == Collection 
      if params["id"].nil?
        render :status => :bad_request, :json => {:error => "Can't delete a collection reference without " +
                                                  "providing the parent collection id. Please use " +
                                                  "the longer url for item deletion."}.to_json and return
      end
      collection = Collection.find_by_id(params["id"])
    else
      collection = Ownership.find_by_item_id(item_id).parent
    end
    
    render :status => :not_found, :json  => {:error => "Could not find parent collection for the item"}.to_json and return if (collection.nil?)
    render :status => :forbidden, :json  => {:error => "The user is not allowed to delete from this collection!"}.to_json and return if (!collection.delete?(@user, @client))
    
    collection.delete_item(item_id)
    render :json => {}.to_json
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
