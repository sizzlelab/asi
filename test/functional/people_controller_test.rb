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
    get :show, { :id => people(:valid_person).id, :format => 'json'}, {:user => people(:valid_person).id}
    assert_response :success
    
    #try to show a person with invalid id
    get :show, { :id => -1, :format => 'json' }, {:user => -1 }
    assert_response :missing
    
  end
  
  def test_get_by_username  
    #get person with valid username
    get :get_by_username, { :username => people(:valid_person).username, :format => 'json'}
    assert_response :success
    #try toget person with non existing username
    get :get_by_username, { :username => "NonExistingUser", :format => 'json'}
    assert_response :missing
    
    
  end
  
  def test_create
    # create valid user
    post :create, { :user => {:username  => "newbie", :password => "newbass", :email => "newbie@testland.gov"}, :format => 'json'}
    assert_response :success
    user = assigns["person"]
    assert_not_nil user
    
    # create another user
    post :create, { :user => {:username  => "secondie", :password => "newbuzz", :email => "secondie@testland.gov"}, :format => 'json'}
    assert_response :success
    
    # check that the created user can be found
    get :get_by_username, { :username  => "newbie", :format  => 'json'}
    assert_response :success
    created_user = assigns["person"]
    assert_equal created_user.username, user.username
  end
  
  def test_update
    # update valid user
    put :update, { :id => people(:valid_person).id, :format => 'json' }, {:user => people(:valid_person).id}
    assert_response :success
    # TODO asserts for checking that the updates really stored correctly
  end
  
  def test_delete
    #delete person with valid id
    delete :delete, { :id => people(:valid_person).id, :format => 'json' }, {:user => people(:valid_person).id }
    assert_response :success
    
    # Check that deleted user is really removed
    get :show, { :id => people(:valid_person).id, :format => 'json' }, {:user => people(:valid_person).id}
    assert_response :missing
    
    #try to delete person with invalid id
    delete :delete, { :id => -1, :format => 'json'}, {:user => -1 }
    assert_response :missing
  end
  
  def test_add_friend
    #add friend to a valid person (as a request at first)
    post :add_friend, { :id  => people(:valid_person).id, :friend_id => people(:not_yet_friend).id, :format  => 'json'}, {:user => people(:valid_person).id}
    assert_response :success
    
    # test that added friend request ís added correctly
    #get :get_by_username, { :username => people(:valid_person).username, :format => 'json'}
    assert  assigns["person"].pending_contacts.include?(assigns["friend"])
    
    # add the friendship also in other direction == accept the request
    post :add_friend, { :id  => people(:not_yet_friend).id, :friend_id => people(:valid_person).id, :format  => 'json'}, {:user => people(:not_yet_friend).id}
    assert_response :success
    
    # test that added friend ís added correctly
    assert  assigns["person"].contacts.include?(assigns["friend"])
    
  end
  
  def test_get_friends
    get :get_friends, {:user_id  => people(:valid_person).id, :format  => 'json'}
    assert_response :success
    assert_not_nil assigns["person"]
    assert_not_nil assigns["friends"]
    assert_equal(assigns["person"].contacts, assigns["friends"])
    
  end
  
  def test_remove_friend
    delete :remove_friend, {:user_id => people(:valid_person), :friend_id => people(:friend).id, :format => 'json'}
    assert_response :success
    
    
  end
end
