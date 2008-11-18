require 'test_helper'
#require 'transactions_controller'

class TransactionsControllerTest < ActionController::TestCase
  
  def setup
    @sender = people(:valid_person)
    @receiver = people(:contact)
    
    @sender_coin_amount_before = @sender.coin_amount
    @receiver_coin_amount_before = @receiver.coin_amount
  end
  
  def test_create_valid_transactions
    post :create, {:transaction => {:sender_id => @sender.id,
                  :receiver_id => @receiver.id,
                  :amount => 3}, :format => 'json'}
     
    assert_response :created
     
    assert_equal(@sender_coin_amount_before - 3, Person.find_by_id(@sender.id).coin_amount)
    assert_equal(@receiver_coin_amount_before + 3, Person.find_by_id(@receiver.id).coin_amount)
  end
  
  def test_try_to_create_too_big_transaction
    post(:create, {:transaction => {:sender_id => @sender.id,
                  :receiver_id => @receiver.id,
                  :amount => 11}, :format => 'json'})
    
    assert_response(406)
     
    assert_equal(@sender.coin_amount, @sender_coin_amount_before)
    assert_equal(@receiver.coin_amount, @receiver_coin_amount_before)
   end
   
   def test_with_receiver_username
     post :create, {:transaction => {:sender_id => @sender.id,
                   :receiver_username => @receiver.username,
                   :amount => 3}, :format => 'json'}
                   
     assert_response :created

     assert_equal(@sender_coin_amount_before - 3, Person.find_by_id(@sender.id).coin_amount)
     assert_equal(@receiver_coin_amount_before + 3, Person.find_by_id(@receiver.id).coin_amount)
    
   end

end

