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

  def test_deprecated_login
    post :create, { :app_name => "ossi", :app_password => "testi", :format => "json"}
    assert_response :bad_request
    json = JSON.parse(@response.body)
    assert json["messages"].size == 1
  end

  def test_client_login
    #test with client only
    post :create, { :session => { :app_name => "ossi", :app_password => "testi"}, :format => 'json'}
    assert_response :created
    assert_not_nil session[:cos_session_id]
    json = JSON.parse(@response.body)
    assert_nil json["entry"]["user_id"]
  end

  def test_create
    post :create, { :session => { :username => "testi", :password => "testi", :app_name => "ossi", :app_password => "testi" }, :format => 'json'}
    assert_response :created
    assert_not_nil session[:cos_session_id]
    assert Role.find_by_person_and_client_id(people(:test).id, sessions(:session10).client_id), "No Role created on first login."

    json = JSON.parse(@response.body)
    assert_equal Person.first(:conditions => {:username => "testi"}).guid, json["entry"]["user_id"]
  end

  def test_user_only
    #test with user only
    post :create, { :session => { :username => "testi", :password => "testia,.u"}, :format => 'json'}
    assert_response :unauthorized
  end

  def test_unauthorized
    #test with erroneus login information
    post :create, { :session => { :username => "testi", :password => "testia,.u", :app_name => "kassi", :app_password => "testi"}, :format => 'json'}
    assert_response :unauthorized

    post :create, { :session => { :username => "testi", :password => "testi", :app_name => "kassi", :app_password => "tesaoeulcrhti"}, :format => 'json'}
    assert_response :unauthorized

    post :create, { :session => { :username => "testi", :password => "testi2513", :app_name => "kassi", :app_password => "t23452esaoeulcrhti"}, :format => 'json'}
    assert_response :unauthorized
  end

  def test_no_person
    post :create, { :session => { :username => "not-there", :password => "not-there", :app_name => "kassi", :app_password => "testi"}, :format => 'json'}
    assert_response :unauthorized
  end

  def test_get
    get :show, { :format => 'json'}, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_equal json["entry"]["user_id"], sessions(:session1).person.guid
  end

  def test_destroy
    # first create the session to destroy
    post :create, { :session => { :username => "testi", :password => "testi", :app_name => "ossi", :app_password => "testi"}, :format => 'json'}
    assert_response :created

    # destroy
    delete :destroy, {:format => 'json'}
    assert_response :success
    assert_nil session[:cos_session_id]

    # create a client only session to destroy
    post :create, { :session => { :app_name => "ossi", :app_password => "testi"}, :format => 'json'}
    assert_response :created
    assert_not_nil session[:cos_session_id]

    # destroy
    delete :destroy, {:format => 'json'}
    assert_response :success
    assert_nil session[:cos_session_id]
  end

  def test_create_without_password
    post :create, { :session => { :app_name => 'ossi', :app_password => 'testi', :username => 'testi'}, :format => 'json'}
    assert_response :bad_request
    json = JSON.parse @response.body
  end

  def test_routing
    with_options :controller => 'sessions', :format => 'json' do |test|
      test.assert_routing({ :method => 'post', :path => '/session'},
        {  :action => 'create'})
      test.assert_routing({ :method => 'get', :path => '/session'},
        {  :action => 'show' })
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
                  { :cos_session_id => sessions(:session1).id }
    assert_response :conflict
  end

  def test_ossi_forbidden_response
    post :create, { :session => { :app_name => 'ossi', :app_password => 'testi', :username => 'testi', :password => 'wrong'}, :format => 'json'}
    assert_response :forbidden
  end


end
