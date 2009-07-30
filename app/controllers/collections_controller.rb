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
      render_json :status => :bad_request, :messages => "The startIndex can't be set to 0. Indexing starts from 1." and return
    end
    render_json :entry => @collection.to_hash(@user, @client, params[:count], params[:startIndex]) and return
  end

  def create
    if params[:collection]
      @collection = Collection.new( params[:collection] )
      # Check: if user submitted an id, but it is not set, there was an error
      if params[:collection][:id] && params[:collection][:id] != @collection.id
        render_json :status => :bad_request, :messages =>  @collection.errors.full_messages and return
      end

      if @user && params[:collection][:owner_id]
        if @collection.indestructible
          render_json :status => :bad_request, :messages => "Cannot set both: owner and indestructible" and return
        elsif params[:collection][:owner_id] != @user.guid
          render_json :status => :bad_request, :messages => "Owner cannot be different than logged in user." and return
        else
          @collection.owner = @user
        end
      else
        if params[:collection][:priv]
          render_json :status => :bad_request, :messages => "Cannot set a collection private without an owner." and return
        end
      end
    else
      @collection = Collection.new
    end
    @collection.client = @client
    @collection.updated_by = @user ? @user.guid : @client.id

    if @collection.save
      render_json :status => :created, :entry => @collection.to_hash(@user, @client) and return
    else
      render_json :status => :bad_request, :messages =>  @collection.errors.full_messages and return
    end
  end

  def update
    render :status => :forbidden and return unless @collection.write?(@user, @client)
    if !params[:collection]
      render_json :status => :bad_request, :messages => "Tried to update collection with no data." and return
    end
    @collection.update_attributes(params[:collection].slice(:metadata, :read_only, :title, :tags, :priv))
    render_json :entry => @collection.to_hash(@user, @client) and return
  end

  def delete
    if ! @collection.delete?(@user, @client)
      render :status => :forbidden and return
    end
    @collection.destroy
    render_json :entry => @collection.to_hash(@user, @client)
  end

  def add
    if ! @collection.write?(@user, @client)
      render_json :status => :forbidden, :messages => "This collection belongs to another client." and return
    end
    render_json :status => :bad_request and return unless @collection.create_item(params[:item], @user, @client)
    @item = @collection.items[-1]
    entry = ( @item.class == Collection ? @item.to_hash(@user, @client) : @item )
    render_json :status => :created, :entry => entry and return
  end

  def delete_item
    item_id = params["item_id"]

    item = TextItem.find_by_id(item_id)
    item = Image.find_by_id(item_id) if item.nil?
    item = Collection.find_by_id(item_id) if item.nil?
    render_json :status => :not_found, :messages => "Could not find the item with id #{item_id}." and return if item.nil?

    if item.class == Collection
      if params["id"].nil?
        render_json :status => :bad_request, :messages => "Can't delete a collection reference without providing the parent collection id. Please use the longer url for item deletion." and return
      end
      collection = Collection.find_by_id(params["id"])
    else
      collection = Ownership.find_by_item_id(item_id).parent
    end

    render_json :status => :not_found, :messages => "Could not find parent collection for the item." and return if (collection.nil?)
    render_json :status => :forbidden, :messages => "The user is not allowed to delete from this collection." and return if (!collection.delete?(@user, @client))

    collection.delete_item(item_id)
    render_json :entry => {} and return
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
      @collection.set_update_info(DateTime.now, (@user ? @user.guid : @client.id))
      # @collection.updated_at = DateTime.now
      # @collection.updated_by = @user ? @user.guid : @client.id
      # @collection.save

    end
  end
end
