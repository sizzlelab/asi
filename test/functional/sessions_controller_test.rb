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
    post :create, { :username => "testi", :password => "testi", :client_name => "ossi", :client_password => "testi", :format => 'json'}
    assert_response :success    

    delete :destroy, {:format => 'json'}
    assert_response :success

    post :create, { :username => "testi", :password => "testia,.u", :client_name => "ossi", :client_password => "testi", :format => 'json'}
    assert_response :unauthorized

    post :create, { :username => "testi", :password => "testi", :client_name => "ossi", :client_password => "tesaoeulcrhti", :format => 'json'}
    assert_response :unauthorized
  end
  
  def test_destroy
    # frist create the session to destroy
    post :create, { :username => "testi", :password => "testi", :client_name => "ossi", :client_password => "testi", :format => 'json'}
    assert_response :success
    # destroy
    delete :destroy, {:format => 'json'}
    assert_response :success
  end
  
  def test_routing
     with_options :controller => 'sessions'  do |test|
       test.assert_routing({ :method => 'post', :path => '/session'}, 
         {  :action => 'create', :format => 'json' })
       test.assert_routing({ :method => 'delete', :path => '/session'}, 
            {  :action => 'destroy', :format => 'json' })
         
     end
   end
end
