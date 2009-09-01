# -*- coding: utf-8 -*-
class CollectionsController < ApplicationController

  before_filter :verify_client

  before_filter :get_or_not_found, :except => [ :create, :index, :delete_item ]

  after_filter :update_updated_at_and_by, :except => [ :create, :index, :show, :delete ]

=begin rapidoc
return_code:: 200

param:: tags - Limits the list to this collections whose tags are an exact match to this parameter.

description:: Retrieves a list of all collections accessible in the current session. The list may be empty.
=end
  def index
    conditions = { :client_id => @client.id }
    if params["tags"]
      conditions.merge!({:tags => params["tags"]})
    end

    @collections = Collection.find(:all, :conditions => conditions, :order => 'updated_at DESC' )
    @collections.reject! { |item| ! item.read?(@user, @client) }

    entries = Array.new
    if @collections
      @collections.each do |item|
        entries << item.info_hash(@user, @client)
      end
    end
    render_json :entry => entries and return
  end
=begin rapidoc
return_code:: 200
return_code:: 403 - The current application or user doesn't have read access to this collection.

param:: count - The number of items per page. If this parameter is unspecified, all items will be included.
param:: startIndex - Index of the first returned item. Indexing starts at 1.

description::  Returns this collection. If this collection contains references to other collections, those without read-access for the current user are hidden automatically from the results.
=end
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

=begin rapidoc
return_code:: 201

param:: collection
  param:: title - A title describing the collection.
  param:: owner_id - The id of the user owning the collection. If unspecified, the collection will belong to the application (and will be visible to all users).
  param:: priv - Whether the collection is private. A private collection is visible to only the owner and their friends.
  param:: read_only - Whether the collection is read-only. Read-only collections can be written to only by their owner; other collections are writable by all users with read access
  param:: indestructible - Whether the collection is indestructible. Indestructible collections cannot be deleted. Can be set only for collections without an owner.
  param:: tags - Keywords for the collection.
  param:: id - You can set the id for the collection yourself if you want. Must be a globally unique (GUID) string, 8-22 characters (preferably 22), and only letters, numbers and underscores allowed.
  param:: metadata
    param:: any_key - Any string
    param:: another_key - Another string

description:: Creates a collection. All parameters are optional.
=end
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


=begin rapidoc
return_code:: 200
return_code:: 403 - The current application or user doesn't have read access to this collection.

param:: collection
  param:: title - A title describing this collection.
  param:: owner_id - The id of the user owning this collection. If unspecified, this collection will belong to the application (and will be visible to all users).
  param:: priv - Whether this collection is private. A private collection is visible to only the owner and their friends.
  param:: read_only - Whether this collection is read-only. Read-only collections can be written to only by their owner; other collections are writable by all users with read access
  param:: tags - Keywords for this collection.
  param:: metadata
    param:: any_key - Any string
    param:: another_key - Another string

description:: Updates the attributes of this collection.
=end
  def update
    render_json :status => :forbidden and return unless @collection.write?(@user, @client)
    if !params[:collection]
      render_json :status => :bad_request, :messages => "Tried to update collection with no data." and return
    end
    @collection.update_attributes(params[:collection].slice(:metadata, :read_only, :title, :tags, :priv))
    render_json :entry => @collection.to_hash(@user, @client) and return
  end

=begin rapidoc
return_code:: 200
return_code:: 403 - The current application or user doesn't have read access to this collection, or this collection is indestructible. You must contact an ASI administrator to delete an indestructible collection.

description:: Deletes this collection.
=end
  def delete
    if ! @collection.delete?(@user, @client)
      render_json :status => :forbidden and return
    end
    @collection.destroy
    render_json :entry => @collection.to_hash(@user, @client)
  end


=begin rapidoc
return_code:: 201
return_code:: 400 - A malformed or unsupported image type was uploaded.
return_code:: 403 - The current application or user doesn't have read access to this collection, or this collection is indestructible. You must contact an ASI administrator to delete an indestructible collection.

param:: item
  param:: content_type - The content type of the new collection item. The content types currently supported are <tt>text/*</tt>, <tt>image/*</tt> and <tt>collection</tt> (a reference to another collection).
  param:: file - A file to be added to the collection (optional).
  param:: body - The body of the item. If a file is given or content_type is not text/*, this parameter is ignored.
  param:: collection_id - Id of an existing collection where the reference will point to. If content_type is not collection this parameter is ignored.

description:: Adds a new item to this collection.
=end
  def add
    if ! @collection.write?(@user, @client)
      render_json :status => :forbidden, :messages => "This collection belongs to another client." and return
    end
    render_json :status => :bad_request and return unless @collection.create_item(params[:item], @user, @client)
    @item = @collection.items[-1]
    entry = ( @item.class == Collection ? @item.to_hash(@user, @client) : @item )
    render_json :status => :created, :entry => entry and return
  end

=begin rapidoc
return_code:: 200
return_code:: 403 - The current combination of application and user is not allowed to delete this item.
return_code:: 404 - The item with the specified id does not exist.

description:: Deletes the item. If the item is a reference to a collection, only the reference is deleted, not the referenced collection.
=end
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
