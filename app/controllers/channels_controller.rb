class ChannelsController < ApplicationController

  before_filter :ensure_client_login
  before_filter :ensure_person_login, :except => :index
  before_filter :get_channel, :except => [:index, :create]
  before_filter :ensure_channel_admin, :only => [:edit, :delete]
  before_filter :ensure_can_read_channel, :only => [:list_subscriptions, :show]

=begin rapidoc
access:: Application
return_code:: 200

description:: Lists channels. Parameters are optional but only one kind of listing (either search or by person id or by group id) is possible at a time. Only channels that current user has access to are listed.

json:: { "entry" => [
  Factory.create_example_channel(:name => "Chanel 9"),
  Factory.create_example_channel(:name => "Chanel 10")
] }
=end
  def index
    if params[:search]
      @channels = Channel.search( params[:search])
    else
      options = Hash.new
      sort_by = 'updated_at'
      sort_order = 'DESC'
      if params[:sort_by]
        if params[:sort_by] == 'created_at'
          sort_by = 'created_at'
        elsif params[:sort_by] == 'name'
          sort_by = 'name'
        elsif params[:sort_by] == 'id'
          sort_by = 'guid'
        end
      end
      if params[:sort_order]
        if params[:sort_order] == 'ascending'
          sort_order = 'ASC'
        elsif params[:sort_order] == 'descending'
          sort_order = 'DESC'
        end
      end
      options[:order] = sort_by + " " + sort_order

      if params[:person_id]
        options.merge!(:joins => :user_subscriptions, :conditions => {'user_subscriptions.person_id' => params[:person_id]})
      elsif params[:group_id]
        options.merge!(:joins => :group_subscriptions, :conditions => {'group_subscriptions.group_id' => params[:group_id]})
      end
      @channels = Channel.all(options)
    end

    @channels.filter_paginate!(params[:per_page], params[:page]) { |c| c.can_read?(@user) }

    size = @channels.count_available

    render_json :entry => @channels, :size => size and return
  end

=begin rapidoc
access:: Application
return_code:: 200

description:: Creates a channel. Parameters are optional except name. Current user is set to channel owner and current client is set to creator_app. Owner is subscribed to the channel (except for group channels).

param:: channel
  param:: name - Channel name. Must be at least two characters long.
  param:: description - Channel description.
  param:: channel_type - Currently public, group and friend channels are supported. Default is public.
  param:: group_id - A single group's id which is then subscribed to the channel if channel_type == 'group'. Current user must have admin rights to that group.

json:: { "entry" =>
  Factory.create_example_channel(:name => "Chanel 9")
}
=end
  def create
    @channel = Channel.new( params[:channel].except(:group_id) )
    @channel.owner = @user
    @channel.creator_app = @client
    if @channel.channel_type == "group" && params[:channel][:group_id]
      group = Group.find_by_id(params[:channel][:group_id])
      if !group || !group.members.exists?(@user)
        render_json :status => :bad_request, :messages => "Group does not exist." and return
      end
      @channel.group_subscribers << group
    end

    if !@channel.save
      render_json :status => :bad_request, :messages => @channel.errors.full_messages and return
    end
    render_json :status => :created, :entry => @channel and return
  end

  def subscribe
    if @channel.channel_type == "group"
      if !params[:group_id]
        render_json :status => :bad_request, :messages => "Must pass explicit group id to subscribe." and return
      end
      group = Group.find_by_id(params[:group_id])
      if !group.admins.exists?(@user)
        render :status => :forbidden and return
      end
      if @channel.group_subscribers.size >= 1
        render_json :status => :bad_request, :messages => "Channel can have only one group subscribed." and return
      end
      @channel.group_subscribers << group
      render :status => :created and return
    else
      if params[:group_id]
        render_json :status => :bad_request, :messages => "Cannot subscribe groups to channels not of type 'group'." and return
      end
      if @channel.can_read?(@user)
        @channel.user_subscribers << @user rescue ActiveRecord::RecordInvalid
        render :status => :created and return
      else
        render :status => :forbidden and return
      end
    end
  end

  def unsubscribe
    if @channel.channel_type == "group"
      if !params[:group_id]
        render_json :status => :bad_request, :messages => "Must declare explicit group id to unsubscribe." and return
      end
      group = Group.find_by_id(params[:group_id])
      if !group || !@channel.group_subscribers.exists?(group)
        render_json :status => :bad_request, :messages => "Group id does not exist or is not subscribed to the channel." and return
      end
      if !group.admins.exists?(@user)
        render :status => :forbidden and return
      end
      @channel.group_subscribers.delete(group)
      render :status => :ok and return
    else
      if params[:person_id]
        if !ensure_same_as_logged_person(@channel.owner.guid)
          render_json :status => :forbidden, :messages => "You are not the channel owner" and return
        end
        person = Person.find_by_guid(params[:person_id])
        if !person
          render_json :status => :bad_request, :messages => "Person not found" and return
        end
      else
        person = @user
      end
      if !@channel.user_subscribers.exists?(person)
        render_json :status => :bad_request, :messages => "Person is not subscribed to channel." and return
      end
      @channel.user_subscribers.delete(person)
      render :status => :ok and return
    end
  end

  def list_subscriptions
    @group_subscriptions = @channel.group_subscribers
    @user_subscriptions = @channel.user_subscribers
    render_json :entry => { :user_subscribers => @user_subscriptions,
                            :group_subscribers => @group_subscriptions
                          } and return
  end

  def show
    render_json :entry => @channel and return
  end

  def edit
    if params[:channel][:owner_id]
      person = Person.find_by_id(params[:channel][:owner_id])
      if !person
        render_json :status => :bad_request, :messages => "Person does not exist." and return
      end
      @channel.owner = person
      if @channel.channel_type != "group"
        @channel.user_subscribers << person rescue ActiveRecord::RecordInvalid
      end
    end

    @channel.update_attributes(params[:channel])

    if !@channel.save
      render_json :status => :bad_request, :messages => @channel.errors.full_messages and return
    end
    render_json :status => :ok, :entry => @channel and return
  end

  def delete
    @channel.delete
    render :status => :ok and return
  end

end
