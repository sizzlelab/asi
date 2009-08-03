require 'test_helper'

class SearchControllerTest < ActionController::TestCase

  test "no query" do
    get :search, { :query => '', :format => 'json' }, { :cos_session_id => sessions(:session1).id }
    assert_response :bad_request
    JSON.parse(@response.body)
  end

  test "search" do
    get :search, { :search => 'te', :format => 'json' }, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    json["entry"].each do |e|
      assert_not_nil e["type"]
      assert_not_nil e["result"]
    end
  end

end
