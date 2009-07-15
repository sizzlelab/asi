module MessagesHelper
  
  def get_message
    @message = @channel.messages.find_by_id(params[:msg_id])
    if !@message
      render :status => :not_found and return
    end
  end

end
