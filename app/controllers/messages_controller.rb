class MessagesController < ApplicationController

  before_filter :get_channel
  before_filter :ensure_can_read_channel, :only => [ :index, :create, :show, :near ]
  before_filter :get_message, :only => [ :delete, :edit, :show, :replies ]

  ##
  # return_code:: 200 - Returns messages in json's entry -field.
  # return_code:: 403 - User has no access to channel.
  # return_code:: 404 - Channel not found.
  # description:: List channel's messages. By default the messages are ordered descending by 'updated_at'.
  # 
  # params::
  #   page:: Pagination page.
  #   per_page:: Pagination per page.
  #   exclude_replies:: Exclude messages which are a replies to other messages. Defaults to false.
  #   search:: Search parameter to search from channel's messages.
  #   sort_order:: Changes the sort order of messages. Allowed values are 'ascending' and 'descending'.
  def index
    if params[:search]
      @messages = Message.search( params[:search],
                                  :per_page => params[:per_page],
                                  :page => params[:page],
                                  :with => { :channel_id => @channel.id})
      size = @messages.total_entries
    else
      options = {}
      if params[:per_page]
        options[:limit] = params[:per_page].to_i
        if params[:page] && params[:page].to_i >= 1
          options[:offset] = params[:per_page].to_i * (params[:page].to_i-1)
        end
      end
      options[:conditions] = {:channel_id => @channel.id }
      if params[:exclude_replies]
        options[:conditions][:reference_to] = nil
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
      @messages = Message.all(options)
      size = Message.count(:conditions => options[:conditions])
    end
    # NOTE: direct render_json doesn't pass @user, @client to models to_hash function.
    render_json :entry => @messages, :size => size and return
  end

  ##
  # return_code:: 200 - Returns messages in json's entry -field.
  # return_code:: 403 - User has no access to channel.
  # return_code:: 404 - Channel not found.
  # description:: Creates a new message.
  # 
  # params::
  #   location:: 'true' if user location is to be used as message location.
  #   message::
  #     title:: Message title
  #     body:: Message content. Text only.
  #     attachment:: Attachment. Currently only urls are advised to be used. In any case the handling of the attachment-field's content is left for the client.
  #     content_type:: Message's attachment's content type.
  #     reference_to:: Message id that this message is a reply to.
  def create
    @message = Message.new(params[:message].except(:reference_to))
    if params[:message][:reference_to]
      ref = Message.find_by_guid( params[:message][:reference_to] )
      if !ref
        render :status => :bad_request and return
      end
      @message.reference_to = ref.id
    end
    @message.channel = @channel
    @message.poster = @user
    if !@message.save
      render_json :status => :bad_request,
                  :messages => @message.errors.full_messages and return
    end

    if params[:location]
        Location.update_object_location(@user, @message.guid)
    end

    render_json :status => :created, :entry => @message and return
  end

  ##
  # return_code:: 200 - Returns message in json's 'entry' field.
  # return_code:: 403 - User has no access to channel.
  # return_code:: 404 - Message not found.
  # description:: Show message.
  def show
    render_json :entry => @message
  end

  ##
  # return_code:: 200 - OK
  # return_code:: 400 - Mestadb query failed.
  # description:: Lists messages near the user.
  #
  # params::
  #   limit:: Maximum amount of messaged to return (Starting from the nearest)
  def near
    options = {}
    options[:conditions] = {:channel_id => @channel.id }
    sort_order = 'DESC'
    options[:order] = 'updated_at ' + sort_order
    elements = Message.all(options)

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
  # return_code:: 200 - Returns messages in json's 'entry' field.
  # return_code:: 403 - User has no access to channel.
  # return_code:: 404 - Channel not found.
  # description:: List replies to a given channel message. By default the messages are ordered descending by 'updated_at'.
  # 
  # params::
  #   page:: Pagination page.
  #   per_page:: Pagination per page.
  #   sort_order:: Changes the sort order of messages. Allowed values are 'ascending' and 'descending'.
  def replies
    options = {}
    if params[:per_page]
      options[:limit] = params[:per_page].to_i
      if params[:page] && params[:page].to_i >= 1
        options[:offset] = params[:per_page].to_i * (params[:page].to_i-1)
      end
    end
    options[:conditions] = {:channel_id => @channel.id, :reference_to => @message.id }
    sort_order = 'DESC'
    if params[:sort_order]
      if params[:sort_order] == 'ascending'
        sort_order = 'ASC'
      elsif params[:sort_order] == 'descending'
        sort_order = 'DESC'
      end
    end
    options[:order] = 'updated_at ' + sort_order
    @messages = Message.all(options)
    size = Message.count(:conditions => options[:conditions])

    render_json :entry => @messages, :size => size and return
  end

  def edit
  end

  ##
  # return_code:: 201 - Message deleted.
  # return_code:: 403 - User has no access to message.
  # return_code:: 404 - Message not found.
  # description:: Delete message. Deleting user has to be either message poster or channel owner.
  def delete
    if ensure_same_as_logged_person(@message.poster.guid)
      @message.delete
      res = Location.delete_location(@message.id)
      render :status => :ok and return
    elsif ensure_same_as_logged_person(@channel.owner.guid)
      @message.delete
      res = Location.delete_location(@message.id)
      render :status => :ok and return
    end
    render :status => :forbidden and return
  end

  private

  def get_message
    @message = Message.find_by_guid(params[:msg_id])
    if !@message
      render :status => :not_found and return
    end
  end

end
