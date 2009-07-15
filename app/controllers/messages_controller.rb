class MessagesController < ApplicationController
  
  before_filter :get_channel
  before_filter :ensure_can_read_channel, :only => [ :list, :create, :show ]
  before_filter :get_message, :only => [ :delete, :edit, :show ]
  
  def list
    @messages = @channel.messages.find_by_id(:all)
    render :status => :ok, :json => @messages.to_json
  end

  def create
    @message = Message.new( :title => params[:title], :poster_id => @person.id, :channel_id => @channel.id,
                            :body => params[:body], :content_type => params[:content_type],
                            :reference_to => params[:reference_to], :attachment => params[:attachment])
    if !@message.validate
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
      ensure_channel_owner
      @message.delete
      render :status => :ok and return
    end
  end

end
