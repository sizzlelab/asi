class BinObjectsController < ApplicationController
  before_filter :ensure_client_login
  before_filter :ensure_person_login, :except => :show
  before_filter :get_bin_object, :only => [ :delete, :edit, :show, :show_data ]
  before_filter :process_params, :only => [ :create, :edit ]

  ##
  # return_code:: 200 - Returns binary objects posted by logged in user in json's entry -field.
  # description:: List binary objects posted by currently logged in user. By default entries are ordered descending by 'updated_at'.
  # 
  # params::
  #   page:: Pagination page.
  #   per_page:: Pagination per page.
  #   sort_order:: Changes the sort order of entries. Allowed values are 'ascending' and 'descending'.
  def index
    options = {}
    options[:conditions] = {:poster_id => @user.id }

    if params[:per_page]
      options[:limit] = params[:per_page].to_i
      if params[:page] && params[:page].to_i >= 1
        options[:offset] = params[:per_page].to_i * (params[:page].to_i-1)
      end
    end

    sort_order = 'DESC'
    if params[:sort_order]
      if params[:sort_order] == 'ascending'
        sort_order = 'ASC'
      elsif params[:sort_order] == 'descending'
        sort_order = 'DESC'
      end
    end
    options[:order] = 'updated_at ' + sort_order

    @bin_objects = BinObject.all(options)
    size = BinObject.count(:conditions => options[:conditions])
    render_json :entry => @bin_objects, :size => size and return
  end
  
  ##
  # return_code:: 200
  # return_code:: 400 - Mestadb query failed.
  # description:: List nearby binary objects posted by currently logged in user.
  #
  # params::
  #   limit:: Maximum amount of objecto to return (Starting from the nearest)
  def near
    options = {}
    options[:conditions] = {:poster_id => @user.id }
    elements = BinObject.all(options)

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
  # return_code:: 200 - Returns binary object, metadata only.
  # return_code:: 403 - User has no access to binary object.
  # return_code:: 404 - Binary object not found.
  # description:: Get the binary object metadata only.
  def show
    render_json :entry => @bin_object
  end

  ##
  # return_code:: 200 - Returns binary object data only.
  # return_code:: 403 - User has no access to binary object.
  # return_code:: 404 - Binary object not found.
  # description:: Get the binary object data only.
  def show_data
    options = { :disposition => 'inline' }
    if @bin_object.content_type
      options[:type] = @bin_object.content_type
    end

    if @bin_object.orig_name
      options[:filename] = @bin_object.orig_name
    end

    unless @bin_object.data
      @bin_object.data = ""
    end

    send_data(@bin_object.data, options)
  end

  ##
  # return_code:: 200 - Returns binary object metadata in json's 'entry' field.
  # description:: Creates a binary object. All parameters are optional. Current user is set to binary object owner. Binary objects can be created using a regular POST or a multipart/form-data upload. In the second case the orig_name and content_type may be supplied by the client, but you can override these by specifying them explicitly.
  # 
  # params::
  #   binobject::
  #     name:: Name of the binary object. If this is not specified and a orig_name if available, name will defaul to orig_name.
  #     data:: Binary object data payload.
  #     content_type:: Binary object's content type.
  #     orig_name:: The original filename (if any) of the binary object.
  #     location:: 'true' if user location is to be used as object location.
  def create
    unless params[:binobject]
      render_json :status => :bad_request and return
    end
    
    @bin_object = BinObject.new(params[:binobject])
    @bin_object.poster = @user
    unless @bin_object.save
      render_json :status => :bad_request,
                  :messages => @bin_object.errors.full_messages and return
    end
    # NOTE: Location of the object is added only if the user has updated his location within 1 hour
    # TODO: Maybe we should allow custom locations in order to upload pictures based on metadata for wxample?
    if params[:binobject][:location]
      res = Location.get_list_locations(@user,@client,@user.guid)
      unless res.nil?
        @location = ActiveSupport::JSON.decode(res.body)["geojson"]["features"][0]
        if Time.parse(@location["properties"]["updated"]) > 1.hour.ago.utc
          res = Location.update_location(@message.guid, @location["geometry"]["coordinates"][1], @location["geometry"]["coordinates"][0], @location["properties"]["name"])
        end
      end
    end

    render_json :status => :created, :entry => @bin_object and return
  end

  ##
  # return_code:: 200 - Returns binary object metadata in json's 'entry' field.
  # description:: Updates a binary object. All parameters are optional. Only the binary object owner can update. If the orig_name and content_type are supplied automatically by the client they will be used, but you can override these by specifying them explicitly.
  # 
  # params::
  #   binobject::
  #     name:: Name of the binary object. If this is not specified and a orig_name if available, name will defaul to orig_name.
  #     data:: Binary object data payload.
  #     content_type:: Binary object's content type.
  #     orig_name:: The original filename (if any) of the binary object.
  def edit
    if ensure_same_as_logged_person(@bin_object.poster.guid)
      @bin_object.update_attributes(params[:binobject])

      if !@bin_object.save
        render_json :status => :bad_request, :messages => @bin_object.errors.full_messages and return
      end
      render_json :status => :ok, :entry => @bin_object and return
    end
    render :status => :forbidden and return
  end

  ##
  # return_code:: 200
  # description:: Deletes this binary object.
  def delete
    if ensure_same_as_logged_person(@bin_object.poster.guid)
      @bin_object.delete
      res = Location.delete_location(@bin_object.guid)
      render :status => :ok and return
    end
    render :status => :forbidden and return
  end

  def process_params
    unless params[:binobject].nil? or params[:binobject][:data].nil?
      if params[:binobject][:data].respond_to?(:content_type) and params[:binobject][:data].respond_to?(:original_filename)
        unless params[:binobject][:content_type]
          params[:binobject][:content_type] = params[:binobject][:data].content_type
        end

        unless params[:binobject][:orig_name]
          params[:binobject][:orig_name] = params[:binobject][:data].original_filename
        end

        # this is a file upload
        params[:binobject][:data] = params[:binobject][:data].read
      end
    end

    # default name to the original_filename property if possible
    if params[:binobject][:orig_name] and not params[:binobject][:name]
      params[:binobject][:name] = params[:binobject][:orig_name]
    end
  end

  def get_bin_object
    @bin_object = BinObject.find_by_guid(params[:binobject_id])
    unless @bin_object
      render :status => :not_found and return
    end
  end

end
