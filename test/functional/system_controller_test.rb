require 'test_helper'

class SystemControllerTest < ActionController::TestCase
  test "authentication" do
    @request.host = "example.org"
    get :rebuild
    assert_response :forbidden
  end
end
