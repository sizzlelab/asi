# -*- coding: utf-8 -*-
class CollectionsController < ApplicationController

  before_filter :verify_client

  before_filter :get_or_not_found, :except => [ :create, :index, :delete_item ]

  after_filter :update_updated_at_and_by, :except => [ :create, :index, :show, :delete ]

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
    if ! @collection.read?(@user, @client)
      @collection = nil
      render :status => :forbidden and return
    end
    if params[:startIndex] == "0"
      @collection = nil
      render :status => :bad_request, :json => "The startIndex can't be set to 0. Indexing starts from 1.".to_json and return
    end
  end

  def create
    @collection = Collection.new(:read_only => params["read_only"],
                                 :indestructible => params["indestructible"],
                                 :tags => params["tags"],
                                 :metadata => params[:metadata],
                                 :title => params["title"],
                                 :priv => params["priv"],
                                 :id => params["id"] )

    # Check: if user submitted an id, but it is not set, there was an error
    if params["id"] && params["id"] != @collection.id
      render :status => :bad_request, :json =>  @collection.errors.full_messages and return
    end

    if @user and params['owner']
      if @collection.indestructible
        render :status => :bad_request, :json => "Cannot set both: owner and indestructible" and return
      elsif params['owner'] != @user.id
        render :status => :bad_request, :json => "Owner cannot be different than logged in user." and return
      else
        @collection.owner = @user
      end
    else
      if params["priv"]
        render :status => :bad_request, :json => "Cannot set a collection private without an owner." and return
      end
    end

    @collection.client = @client
    @collection.updated_by = @user ? @user.id : @client.id

    if @collection.save
      render :status => :created
    else
      render :status => :bad_request, :json =>  @collection.errors.full_messages and return
    end
  end

  def update
    render :status => :forbidden and return unless @collection.write?(@user, @client)
    @collection.update_attributes({:metadata  => params[:metadata ]})
    @collection.update_attributes({:read_only => params[:read_only]}) if params[:read_only]
    @collection.update_attributes({:title => params[:title]}) if params[:title]
    @collection.update_attributes({:tags => params[:tags]}) if params[:tags]
    @collection.update_attributes({:priv => params[:priv]}) if params[:priv]
  end

  def delete
    if ! @collection.delete?(@user, @client)
      render :status => :forbidden and return
    end
    @collection.destroy
  end

  def add
    if ! @collection.write?(@user, @client)
      render :status => :forbidden, :json => "This collection belongs to another client.".to_json and return
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

  #update the fields "updated_at" and "updated_by"
  def update_updated_at_and_by
    #logger.info { "FILTTERISSÄ: #{response.headers["Status"]}" }
    if response.headers["Status"] =~ /^20/
      @collection.set_update_info(DateTime.now, (@user ? @user.id : @client.id))
      # @collection.updated_at = DateTime.now
      # @collection.updated_by = @user ? @user.id : @client.id
      # @collection.save

    end
  end
end
