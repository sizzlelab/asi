require 'test_helper'
require 'sessions_controller'

class SessionsControllerTest < ActionController::TestCase
  fixtures :people

  def setup
    @controller = SessionsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end
  
  def test_create
    post :create, { :username => "testi", :password => "testi", :client_name => "ossi", :client_password => "testi", :format => 'json'}
    assert_response :success
    assert_not_nil session[:session_id]
    json = JSON.parse(@response.body)

    delete :destroy, {:format => 'json'}
    assert_response :success
    json = JSON.parse(@response.body)

    #test with user only
    post :create, { :username => "testi", :password => "testia,.u", :format => 'json'}
    assert_response :unauthorized

    post :create, { :username => "testi", :password => "testi", :format => 'json'}
    assert_response :unauthorized
    
    #test with client only
    post :create, { :client_name => "ossi", :client_password => "testi", :format => 'json'}
    assert_response :success
    assert_not_nil session[:session_id]
    json = JSON.parse(@response.body)
    
    delete :destroy, {:format => 'json'}
    assert_response :success
    json = JSON.parse(@response.body)
    
    #test with erroneus login information
    post :create, { :username => "testi", :password => "testia,.u", :client_name => "ossi", :client_password => "testi", :format => 'json'}
    assert_response :unauthorized

    post :create, { :username => "testi", :password => "testi", :client_name => "ossi", :client_password => "tesaoeulcrhti", :format => 'json'}
    assert_response :unauthorized
    
    post :create, { :username => "testi", :password => "testi2513", :client_name => "ossi", :client_password => "t23452esaoeulcrhti", :format => 'json'}
    assert_response :unauthorized
  end
  
  def test_destroy
    # frist create the session to destroy
    post :create, { :username => "testi", :password => "testi", :client_name => "ossi", :client_password => "testi", :format => 'json'}
    assert_response :success
    json = JSON.parse(@response.body)

    # destroy
    delete :destroy, {:format => 'json'}
    assert_response :success
    assert_nil session[:session_id]
    
    # create a client only session to destroy
    post :create, { :client_name => "ossi", :client_password => "testi", :format => 'json'}
    assert_response :success
    assert_not_nil session[:session_id]
    json = JSON.parse(@response.body)

    # destroy
    delete :destroy, {:format => 'json'}
    assert_response :success
    json = JSON.parse(@response.body)
    assert_nil session[:session_id]
  end
  
  def test_routing
    with_options :controller => 'sessions', :format => 'json' do |test|
      test.assert_routing({ :method => 'post', :path => '/session'}, 
        {  :action => 'create'})
      test.assert_routing({ :method => 'delete', :path => '/session'}, 
        {  :action => 'destroy' }) 
    end
  end
end
