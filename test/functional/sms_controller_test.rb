require 'test_helper'

class SmsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index, {:format => "json" }, { :cos_session_id => sessions(:session14).id } 
    assert_response :success 
  end
  def test_should_send_and_mark_sms
    post :smssend, {:format => "json", :text => 'pysmsd_test test message for functional tests.', :number => APP_CONFIG.pysmsd_number }, { :cos_session_id => sessions(:session14).id }
    assert_response :success

    sleep 5 # unfortunately quite arbitrary, have to wait for the message to get there first

    get :index, {:format => "json" }, { :cos_session_id => sessions(:session14).id }
    assert_response :success
#    print @response.body
    json = JSON.parse(@response.body)
#    print json["entry"]["messages"][0]
    
    post :smssend, {:format => "json", :ids => json["entry"]["messages"][0]["id"] }, { :cos_session_id => sessions(:session14).id }
    assert_response :success
  end
  def test_invalid_send_sms_methods
    [:get, :put, :delete].each do |http_method|
      send http_method, :smssend, {:format => "json", :text => 'text', :number => '+358503012496' }, { :cos_session_id => sessions(:session14).id }
      assert_response 405
    end
  end
  def test_invalid_index_methods
    [:post, :put, :delete].each do |http_method|
      send http_method, :index, {:format => "json" }, { :cos_session_id => sessions(:session14).id }
      assert_response 405
    end
  end
end
