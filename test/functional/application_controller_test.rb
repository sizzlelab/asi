require 'test_helper'
require 'json'

class ApplicationControllerTest < ActionController::TestCase

  def setup
    @controller = ApplicationController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end

  def test_index
    get :index
    assert_response :success
  end

end
