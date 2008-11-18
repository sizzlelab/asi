class TransactionsController < ApplicationController
  
  def create
    if ! params[:transaction][:receiver_id]
      params[:transaction][:receiver_id] = Person.find_by_username(params[:transaction][:receiver_username]).id
      params[:transaction].delete(:receiver_username)
    end
     @sender = Person.find(params[:user_id])
     @receiver = Person.find(params[:transaction][:receiver_id])
     if(@sender.coin_amount - params[:transaction][:amount].to_i >= PURSE_LIMIT)
        Transaction.transaction do
          
          @sender.coin_amount = @sender.coin_amount - params[:transaction][:amount].to_i
          @receiver.coin_amount = @receiver.coin_amount + params[:transaction][:amount].to_i
        
          @transaction = Transaction.new(params[:transaction].merge(:sender_id => params[:user_id]))
          
          @sender.save
          @receiver.save
          @transaction.save
          
          render :xml => @transaction.to_xml, :status => :created, 
                :location => url_for(:controller=> "people") + "/#{params[:user_id]}/@transactions/#{@transaction.id}"
        end
    #logger.info url_for(:controller=> "people") + "/#{params[:user_id]}/@transactions/#{@transaction.id}"
     else
        render :status => 406, :json  => {:error => "Not enough money on sender's account."}.to_json and return
     end
  end
  
  #TODO add check that sender and receiver not the same...

  def get
  end

end

