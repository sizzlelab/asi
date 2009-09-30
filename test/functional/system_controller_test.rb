require 'test_helper'

class SystemControllerTest < ActionController::TestCase
  test "reindex" do
    get :reindex
    assert_response :success
  end
end
