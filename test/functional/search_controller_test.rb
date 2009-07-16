require 'test_helper'

class SearchControllerTest < ActionController::TestCase

  test "no query" do
    get :search, { :query => '', :format => 'json' }, { :cos_session_id => sessions(:session1).id }
    assert_response :bad_request
    JSON.parse(@response.body)
  end

  test "search" do
    get :search, { :query => 'TKK', :format => 'json' }, { :cos_session_id => sessions(:session1).id }
    assert_response :success
    JSON.parse(@response.body)
  end

end
