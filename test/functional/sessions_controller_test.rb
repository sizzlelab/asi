require 'test_helper'
require 'sessions_controller'

class SessionsController; def rescue_action(e) raise e end; end

class SessionsControllerTest < ActionController::TestCase
  fixtures :people

  def setup
    @controller = SessionsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new

    @first_id = sessions(:session1).id
  end
  
  def test_create
    post :create, { :session  => {:name => "testi", :password => "testi"}, :format => 'json'}
    assert_response :success
  end
  
  def test_destroy
    delete :destroy #, {:format => 'json'}
    #assert_response :success  #TODO find out why returns always 302?
    
  end
  
  def test_routing
     
     with_options :controller => 'sessions'  do |test|
       test.assert_routing({ :method => 'post', :path => '/session'}, 
         {  :action => 'create', :format => 'json' })

     end
   end
end
