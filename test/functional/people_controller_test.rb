require 'test_helper'

class PeopleControllerTest < ActionController::TestCase
  
  def setup
    @controller = PeopleController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end
  
  # TODO more comprehensive tests
  
  def test_index
    get :index
    assert_response :success 
    assert_not_nil assigns(:people)
  end
  
  def test_show
    #show person with valid id
    get :show, { :id => people(:valid_person).id}, {:user => people(:valid_person).id}
    assert_response :success
    
    #try to show a person with invalid id
    delete :delete, { :id => -1}, {:user => -1 }
    assert_response :missing
    
  end
  
  def test_create
    # create valid user
    post :create, { :username => people(:valid_person).username, :password => people(:valid_person).password}
    assert_response :success
    
    # TODO
    # check that the created user can be found
    #get :show, { :id => people(:valid_person).id}, {:user => people(:valid_person).id}
    #assert_response :success
    
  end
  
  def test_update
    # update valid user
    put :update, { :id => people(:valid_person).id }, {:user => people(:valid_person).id}
    assert_response :success
    # TODO asserts for checking that the updates really stored correctly
  end
  
  def test_delete
    #delete person with valid id
    delete :delete, { :id => people(:valid_person).id}, {:user => people(:valid_person).id }
    assert_response :success
    
    # Check that deleted user is really removed
    get :show, { :id => people(:valid_person).id}, {:user => people(:valid_person).id}
    assert_response :missing
    
    #try to delete person with invalid id
    delete :delete, { :id => -1}, {:user => -1 }
    assert_response :missing
  end
  
end
