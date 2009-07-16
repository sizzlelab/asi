class MessagesController < ApplicationController
  
  before_filter :get_channel
  before_filter :ensure_can_read_channel, :only => [ :list, :create, :show ]
  before_filter :get_message, :only => [ :delete, :edit, :show ]
  
  def list
    @messages = @channel.messages
    guids = []
    @messages.each do |msg|
      guids.push(msg.guid)
    end
    render :status => :ok, :json => { :messages => guids }.to_json
  end

  def create
    @message = Message.new( :title => params[:title], :poster_id => @user.id, :channel_id => @channel.id,
                            :body => params[:body], :content_type => params[:content_type],
                            :reference_to => params[:reference_to], :attachment => params[:attachment])
    if !@message.valid?
      render :status => :bad_request and return
    end
    if !@message.save
      render :status => 500 and return
    end
    render :status => :created, :json => @message.to_json and return
  end

  def show
    render :status => :ok, :json => @message.to_json
  end

  def edit
    
  end

  def delete
    if ensure_same_as_logged_person(@message.poster.id)
      @message.delete
      render :status => :ok and return
    else
      if !ensure_same_as_logged_person(@channel.owner.id)
        render :status => :forbidden and return
      end
      @message.delete
      render :status => :ok and return
    end
  end

  private

  def get_message
    @message = @channel.messages.find_by_guid(params[:msg_id])
    if !@message
      render :status => :not_found and return
    end
  end

end
