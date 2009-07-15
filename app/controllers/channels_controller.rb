class ChannelsController < ApplicationController

  before_filter :ensure_client_login  
  before_filter :ensure_person_login, :except => :list
  before_filter :get_channel, :except => [:list, :create]
  before_filter :ensure_channel_owner, :only => [:edit, :delete]
  before_filter :ensure_can_read_channel, :only => [:list_subscriptions, :show]
  
  def list
    results = []
    if params[:search]
#      results.push Channel.find_by_contents( params[:search] )
    end
    if params[:person_id]
      UserSubscription.find_each(:conditions => {:person_id => params[:person_id]}) do |subscription|
        results.push Channel.find_by_id(subscription.channel.id)
      end
    end
    if params[:group_id]
      GroupSubscription.find_each(:conditions => {:group_id => params[:group_id]}) do |subscription|
        results.push Channel.find_by_id(subscription.channel.id)
      end
    end
    
    if !params[:search] && !params[:person_id] && !params[:group_id]
      results.push Channel.find(:all)
    end
    
    results.flatten!
    
    results.each do |channel|
      results.delete(channel) if !can_read_channel?(@user, channel)
    end
    
    render :status => :ok, :json => results.uniq.to_json and return
  end
  
  def create
    @channel = Channel.new( :name => params[:name], :description => params[:description], 
                            :owner => @user, :creator_app => @client )
    if params[:type]
      @channel.channel_type = params[:type]
    else
      @channel.channel_type = "public"
    end
    
    if params[:id] || !params[:id] == ""
      @channel.guid = params[:id]
    end
    
    if params[:type] == "group" && ( !params[:name] || params[:name] == "" )
      if !params[:group_subscriptions] || params[:group_subscriptions].class == "Array"
        render :status => :bad_request and return
      end
      @channel.name = Group.find_by_id(params[:group_subscriptions]).title
    end    
    
    if params[:user_subscriptions]
      begin
        users = Person.find(params[:user_subscriptions])
      rescue ActiveRecord::RecordNotFound
        render :status => :not_found and return
      end
      @channel.user_subscribers << users
    end
    if params[:group_subscriptions]
      begin
        groups = Group.find(params[:group_subscriptions])
      rescue ActiveRecord::RecordNotFound
        render :status => :not_found and return
      end
      @channel.group_subscribers << groups
    end
    
    if !@channel.valid?
      render :status => :bad_request, :message => "Data validation failed." and return
    end
    if !@channel.save
      render :status => 500, :message => "Something weird went wrong." and return
    end
    render :status => :created, :json => @channel.to_json and return
  end

  def subscribe
    subscription = false
    if params[:group_subscriptions]
      if !ensure_same_as_logged_person(@channel.owner_id)
        render :status => :forbidden and return
      end
      begin
        groups = Group.find(params[:group_subscriptions])
      rescue ActiveRecord::RecordNotFound
        render :status => :not_found and return
      end
      @channel.group_subscribers << groups
      subscription = true
    end
    if params[:user_subscriptions]
      if !ensure_same_as_logged_person(@channel.owner_id)
        render :status => :forbidden and return
      end
      begin
        users = Person.find(params[:user_subscriptions])
      rescue ActiveRecord::RecordNotFound
        render :status => :not_found and return
      end
      @channel.user_subscribers << users
      subscription = true
    end
    if !subscription && ( @channel.channel_type == "friend" || @channel.channel_type == "public" )
      if !can_read_channel?(@user, @channel)
        render :status => :forbidden and return
      end
      @channel.user_subscribers << @user
      subscription = true
    end
    if subscription
      render :status => :created and return
    else
      render :status => :forbidden and return
    end
  end

  def unsubscribe
    if params[:user_subscriptions]
      if ensure_same_as_logged_person(@channel.owner.id)
        begin
          users = Person.find(params[:user_subscriptions])
        rescue ActiveRecord::RecordNotFound
          render :status => :not_found and return
        end
        @channel.user_subscribers.delete(users)
      else
        render :status => :forbidden and return
      end
    end
    if params[:group_subscriptions]
      if ensure_same_as_logged_person(@channel.owner.id)
        begin
          groups = Group.find(params[:group_subscriptions])
        rescue ActiveRecord::RecordNotFound
          render :status => :not_found and return
        end
        @channel.group_subscribers.delete(groups)
      else
        render :status => :forbidden and return
      end
    end
     
    if !params[:user_subscriptions] && !params[:group_subscriptions]
      if ensure_same_as_logged_person(@channel.owner.id)
        render :status => :forbidden and return
      end
      @channel.user_subscribers.delete(@user)
    end
    render :status => :ok and return
  end
  
  def list_subscriptions
    @group_subscriptions = @channel.group_subscriber_ids
    @user_subscriptions = @channel.user_subscriber_ids
    render :status => :ok, :json => {:user_subscriptions => @user_subscriptions, 
                                     :group_subscriptions => @group_subscriptions}.to_json and return
  end

  def show
    render :status => :ok, :json => @channel.to_json and return
  end

  def edit
    if params[:name]
      @channel.name = params[:name]
    end
    if params[:description]
      @channel.description = params[:description]
    end
    if params[:owner]
      person = Person.find_by_id(params[:owner])
      if !person
        render :status => :not_found and return
      end
      @channel.owner = person
      @channel.user_subscribers << person
#      @channel.user_subscribers.delete(@user)
    end
    if !@channel.valid?
      render :status => :bad_request and return
    end
    if !@channel.save
      render :status => 500, :message => "Something weird went wrong." and return
    end
    render :status => :created, :json => @channel.to_json and return
  end

  def delete
    @channel.delete
    render :status => :ok and return 
  end

  private
  
  def can_read_channel?(user, channel)
    if channel.channel_type == "public"
      return true
    end 
    if user
      if channel.channel_type == "friend"
        return true if user.contacts.find_by_id(channel.owner.id)
      end
      if channel.channel_type == "group"
        channel.group_subscribers.each do |subscription|
          return true if user.groups.find_by_id(subscription.id)
        end
      end
    end
    return false 
  end
  
  def ensure_channel_owner
    if !ensure_same_as_logged_person(@channel.owner_id)
      render :status => :forbidden and return
    end 
  end
  
  def ensure_can_read_channel
    if !can_read_channel?(@user, @channel)
      render :status => :forbidden and return
    end
  end
  
  def get_channel
    @channel = Channel.find_by_guid( params[:channel_id] )
    if !@channel
      render :status => :not_found and return
    end
  end  

end
