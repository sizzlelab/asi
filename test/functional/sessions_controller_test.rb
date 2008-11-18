require 'test_helper'
require 'sessions_controller'
require 'json'

class SessionsControllerTest < ActionController::TestCase
  fixtures :people, :sessions

  def setup
    @controller = SessionsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end
  
  def test_create
    post :create, { :username => "testi", :password => "testi", :app_name => "ossi", :app_password => "testi", :format => 'json'}
    assert_response :created
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
    post :create, { :app_name => "ossi", :app_password => "testi", :format => 'json'}
    assert_response :created
    assert_not_nil session[:session_id]
    json = JSON.parse(@response.body)
    
    delete :destroy, {:format => 'json'}
    assert_response :success
    json = JSON.parse(@response.body)
    
    #test with erroneus login information
    post :create, { :username => "testi", :password => "testia,.u", :app_name => "ossi", :app_password => "testi", :format => 'json'}
    assert_response :unauthorized

    post :create, { :username => "testi", :password => "testi", :app_name => "ossi", :app_password => "tesaoeulcrhti", :format => 'json'}
    assert_response :unauthorized
    
    post :create, { :username => "testi", :password => "testi2513", :app_name => "ossi", :app_password => "t23452esaoeulcrhti", :format => 'json'}
    assert_response :unauthorized
  end
  
  def test_get
    get :get, { :format => 'json'}, { :session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_equal json["user_id"], sessions(:session1).person_id  
  end

  def test_destroy
    # frist create the session to destroy
    post :create, { :username => "testi", :password => "testi", :app_name => "ossi", :app_password => "testi", :format => 'json'}
    assert_response :created
    json = JSON.parse(@response.body)

    # destroy
    delete :destroy, {:format => 'json'}
    assert_response :success
    assert_nil session[:session_id]
    
    # create a client only session to destroy
    post :create, { :app_name => "ossi", :app_password => "testi", :format => 'json'}
    assert_response :created
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
      test.assert_routing({ :method => 'get', :path => '/session'}, 
        {  :action => 'get' }) 
      test.assert_routing({ :method => 'delete', :path => '/session'}, 
        {  :action => 'destroy' })
    end
  end

  def test_error_reporting

    delete :destroy, { :format => 'json' }
    assert_response :not_found

    post :create, { :format => 'json' }
    assert_response :unauthorized

    post :create, { :username => "testi", :password => "testi", 
                    :app_name => "ossi", :app_password => "testi", :format => 'json' },
                  { :session_id => sessions(:session1).id } 
    assert_response :conflict
  end
end
