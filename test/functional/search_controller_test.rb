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
    types = []
    all_types = %w(Group Person Channel Message)
    json["entry"].each do |e|
      assert_not_nil e["type"]
      assert(all_types.include?(e["type"]), "Unknown result type #{e['type']}")
      types << e["type"]
      assert_not_nil e["result"]
    end
    all_types.each { |t| assert types.include?(t), "No test result of type #{t}" }
  end
end
