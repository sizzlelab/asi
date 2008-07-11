require 'test_helper'
require 'json'

class ClientDataControllerTest < ActionController::TestCase

  def setup
    @controller = ClientDataController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end

  def test_show
    get :show, { :app_id => clients(:one).id, :user_id => people(:valid_person).id, :format => 'json' }, 
               { :session_id => sessions(:session1).id }
    assert_response :success
    assert_not_nil assigns["set"]
    json = JSON.parse(@response.body)
    client_data_pairs.each { |item| assert_equal json[item.key], item.value }
  end

  def test_authorization
    get :show, { :app_id => clients(:two).id, :user_id => people(:valid_person).id, :format => 'json' }, 
               { :session_id => sessions(:session1).id }
    assert_response :forbidden
    assert_nil assigns["set"]
    json = JSON.parse(@response.body)
  end

  def test_put
    put :update, { :data => { :foo => "bar", :bar => "foo" }, 
                   :app_id => clients(:one).id, 
                   :user_id => people(:valid_person).id, 
                   :format => 'json' }, 
                 { :session_id => sessions(:session1).id }
    assert_response :success
    
    json = JSON.parse(@response.body)
    assert_equal json["foo"], "bar"
    assert_equal json["bar"], "foo"
  end

  def test_routing
    user_id = "oeusrch"
    app_id = "aoeucrsh"
    with_options :controller => 'client_data', :format => 'json' do |test|
      test.assert_routing({ :method => 'get', :path => "/appdata/#{user_id}/@self/#{app_id}" }, 
                          { :action => 'show', :user_id => user_id, :app_id => app_id })
      test.assert_routing({ :method => 'put', :path => "/appdata/#{user_id}/@self/#{app_id}" }, 
                          { :action => 'update', :user_id => user_id, :app_id => app_id })

    end
  end
end
