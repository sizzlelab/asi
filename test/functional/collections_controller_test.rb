require 'test_helper'

class CollectionsControllerTest < ActionController::TestCase

  def setup
    @controller = CollectionsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end

  def test_index
    get :index
    assert_response :success
  end

  def test_show
    get :show, { :id => collections(:one).id }
    assert_response :success
  end

end
