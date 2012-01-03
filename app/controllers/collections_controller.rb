# -*- coding: utf-8 -*-
class CollectionsController < ApplicationController

  before_filter :verify_client

  before_filter :get_or_not_found, :except => [ :create, :index, :delete_item, :near ]

  after_filter :update_updated_at_and_by, :except => [ :create, :index, :show, :delete, :near ]

  ##
  # return_code:: 200 - OK
  # description:: Retrieves a list of all collections accessible in the current session. The list may be empty.
  # 
  # params::
  #   tags:: Limits the list to this collections whose tags are an exact match to this parameter.
  def index
    conditions = { :client_id => @client.id }
    if params["tags"]
      conditions.merge!({:tags => params["tags"]})
    end

    @collections = Collection.where(conditions).order('updated_at DESC')
    @collections.reject! { |item| ! item.read?(@user, @client) }

    entries = Array.new
    if @collections
      @collections.each do |item|
        entries << item.info_hash(@user, @client)
      end
    end
    render_json :entry => entries and return
  end

  ##
  # return_code:: 200 - OK
  # return_code:: 403 - The current application or user doesn't have read access to this collection.
  # description::  Returns this collection. If this collection contains references to other collections, those without read-access for the current user are hidden automatically from the results.
  # 
  # params::
  #   count:: The number of items per page. If this parameter is unspecified, all items will be included.
  #   startIndex:: Index of the first returned item. Indexing starts at 1.
  def show
    if ! @collection.read?(@user, @client)
      @collection = nil
      render_json :status => :forbidden and return
    end
    if params[:startIndex] == "0"
      @collection = nil
      render_json :status => :bad_request, :messages => "The startIndex can't be set to 0. Indexing starts from 1." and return
    end
    render_json :entry => @collection.to_hash(@user, @client, params[:count], params[:startIndex]) and return
  end

  ##
  # return_code:: 200 - OK
  # return_code:: 400 - Mestadb query failed.
  # description:: Lists collections near the user
  #
  # params::
  #   limit:: Maximum amount of collections to return (Starting from the nearest)
  #   tags:: Limit to collections that match this tag
  def near
    conditions = { :client_id => @client.id }
    if params["tags"]
      conditions.merge!({:tags => params["tags"]})
    end

    @collections = Collection.where(conditions).order('updated_at DESC')
    @collections.reject! { |item| ! item.read?(@user, @client) }
    elements = @collections

    if params[:limit].nil?
      limit = 50
    else
      limit = params[:limit]
    end

    list = Location.get_near(@user, @client, elements, nil, 100000, limit)

    if list.class != Array
      render_json list and return
    end
    render_json :entry => list and return	
  end

  ##
  # return_code:: 201 - Created
  # description:: Creates a collection. All parameters are optional.
  # 
  # params::
  #   location:: 'true' if user location is to be used as this collections location.
  #   collection::
  #     title:: A title describing the collection.
  #     owner_id:: The id of the user owning the collection. If unspecified, the collection will belong to the application (and will be visible to all users).
  #     priv:: Whether the collection is private. A private collection is visible to only the owner and their friends.
  #     read_only:: Whether the collection is read-only. Read-only collections can be written to only by their owner; other collections are writable by all users with read access
  #     indestructible:: Whether the collection is indestructible. Indestructible collections cannot be deleted. Can be set only for collections without an owner.
  #     tags:: Keywords for the collection.
  #     id:: You can set the id for the collection yourself if you want. Must be a globally unique (GUID) string, 8-22 characters (preferably 22), and only letters, numbers and underscores allowed.
  #     metadata::
  #       any_key:: Any string
  #       another_key:: Another string
  def create
    if params[:collection]
      @collection = Collection.new( params[:collection] )
      # Check: if user submitted an id, but it is not set, there was an error
      if params[:collection][:id] && params[:collection][:id] != @collection.id
        render_json :status => :bad_request, :messages =>  @collection.errors.full_messages and return
      end

      if params[:location]
        Location.update_object_location(@user, @collection.id)
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

  ##
  # return_code:: 200 - OK
  # return_code:: 403 - The current application or user doesn't have read access to this collection.
  # description:: Updates the attributes of this collection.
  # 
  # params::
  #  collection::
  #     title:: A title describing this collection.
  #     owner_id:: The id of the user owning this collection. If unspecified, this collection will belong to the application (and will be visible to all users).
  #     priv:: Whether this collection is private. A private collection is visible to only the owner and their friends.
  #     read_only:: Whether this collection is read-only. Read-only collections can be written to only by their owner; other collections are writable by all users with read access
  #     tags:: Keywords for this collection.
  #     metadata
  #       any_key:: Any string
  #       another_key:: Another string
  def update
    render_json :status => :forbidden and return unless @collection.write?(@user, @client)
    if !params[:collection]
      render_json :status => :bad_request, :messages => "Tried to update collection with no data." and return
    end
    @collection.update_attributes(params[:collection].slice(:metadata, :read_only, :title, :tags, :priv))
    render_json :entry => @collection.to_hash(@user, @client) and return
  end

  ##
  # return_code:: 200 - OK
  # return_code:: 403 - The current application or user doesn't have read access to this collection, or this collection is indestructible. You must contact an ASI administrator to delete an indestructible collection.
  # description:: Deletes this collection.
  def delete
    if ! @collection.delete?(@user, @client)
      render_json :status => :forbidden and return
    end
    @collection.destroy
    res = Location.delete_location(@collection.id)
    render_json :entry => @collection.to_hash(@user, @client)
  end


  ##
  # return_code:: 201 - Created
  # return_code:: 400 - A malformed or unsupported image type was uploaded.
  # return_code:: 403 - The current application or user doesn't have read access to this collection, or this collection is indestructible. You must contact an ASI administrator to delete an indestructible collection.
  # description:: Adds a new item to this collection.
  #
  # params::
  #   item::
  #     content_type:: The content type of the new collection item. The content types currently supported are <tt>text/*</tt>, <tt>image/*</tt> and <tt>collection</tt> (a reference to another collection).
  #     file:: A file to be added to the collection (optional).
  #     body:: The body of the item. If a file is given or content_type is not text/*, this parameter is ignored.
  #     collection_id:: Id of an existing collection where the reference will point to. If content_type is not collection this parameter is ignored.
  def add
    if ! @collection.write?(@user, @client)
      render_json :status => :forbidden, :messages => "This collection belongs to another client." and return
    end
    render_json :status => :bad_request and return unless @collection.create_item(params[:item], @user, @client)
    @item = @collection.items[-1]
    entry = ( @item.class == Collection ? @item.to_hash(@user, @client) : @item )
    render_json :status => :created, :entry => entry and return
  end

  ##
  # return_code:: 200 - OK
  # return_code:: 403 - The current combination of application and user is not allowed to delete this item.
  # return_code:: 404 - The item with the specified id does not exist.
  # description:: Deletes the item. If the item is a reference to a collection, only the reference is deleted, not the referenced collection.
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
;
    render_json :status => :not_found, :messages => "Could not find parent collection for the item." and return if (collection.nil?)
    render_json :status => :forbidden, :messages => "The user is not allowed to delete from this collection." and return if (!collection.delete?(@user, @client))

    collection.delete_item(item_id)
    Location.delete_location(item_id)
    render_json :entry => {} and return
  end


  private

  def verify_client
    if @client == nil or params["app_id"].to_s != @client.id.to_s
      render_json :status => :forbidden and return
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
