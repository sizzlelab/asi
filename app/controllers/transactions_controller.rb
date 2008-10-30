class TransactionsController < ApplicationController
  def create
    
    if ! params[:transaction][:receiver_id]
      params[:transaction][:receiver_id] = Person.find_by_username(params[:transaction][:receiver_username]).id
      params[:transaction].delete(:receiver_username)
    end
    @transaction = Transaction.new(params[:transaction].merge(:sender_id => params[:user_id]))
    @transaction.save
    #logger.info url_for(:controller=> "people") + "/#{params[:user_id]}/@transactions/#{@transaction.id}"
    
    render :xml => @transaction.to_xml, :status => :created, 
           :location => url_for(:controller=> "people") + "/#{params[:user_id]}/@transactions/#{@transaction.id}"
  end

  def get
  end

end
