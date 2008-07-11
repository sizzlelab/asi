# -*- coding: iso-8859-1 -*-
require 'test_helper'
require 'json'

class PeopleControllerTest < ActionController::TestCase
  fixtures :sessions
  
  def setup
    @controller = PeopleController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    PersonName.rebuild_index
  end
  
  # TODO more comprehensive tests
  
  def test_index
    # Should find nothing
    get :index, { :format => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success 
    assert_not_nil assigns(:people)
  end
  
  def test_show
    #show person with valid id
    get :show, { :user_id => people(:valid_person).id, :format => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success
    assert_not_nil assigns["person"]
    json = JSON.parse(@response.body)
    assert_equal people(:valid_person).id, json["id"]
    assert_nil json["password"]
    
    #try to show a person with invalid id
    get :show, { :user_id => -1, :format => 'json' }
    assert_response :missing
    
  end
  
  def test_get_by_username  
    #get person with valid username
    get :get_by_username, { :username => people(:valid_person).username, :format => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success
    assert_equal(assigns["person"].username, people(:valid_person).username )
    #try to get person with non existing username
    get :get_by_username, { :username => "NonExistingUser", :format => 'json' }
    assert_response :missing
  end
  
  def test_create
    # create valid user
    post :create, { :person => {:username  => "newbie", :password => "newbass", :email => "newbie@testland.gov" }, :format => 'json'}, { :session_id => sessions(:client_only_session).id }
    assert_response :success 
    user = assigns["person"] 
    assert_not_nil user
    
    # create another user
    post :create, { :person => {:username  => "secondie", :password => "newbuzz", :email => "secondie@testland.gov" }, :format => 'json'}
    assert_response :success  
    
    # check that the created user can be found
    get :get_by_username, { :username  => "newbie", :format  => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success
    created_user = assigns["person"]
    assert_equal created_user.username, user.username
  end

  def test_update
    # update valid user
    testing_email = "newemail@oldserv.er"
    put :update, { :user_id => people(:valid_person).id, :person => {:email => testing_email }, :format => 'json' }, 
                 { :session_id => sessions(:session1).id }
    assert_response :success
    # asserts for checking that the updates really stored correctly
    assert_equal(assigns["person"].email, testing_email)
    # assert that no changed value has not changed
    assert_equal(assigns["person"].username, people(:valid_person).username)
    
    # try to update other user than self
    put :update, { :user_id => people(:friend).id, :person => {:email => testing_email }, :format => 'json' }, 
                 { :session_id => sessions(:session1).id }
    assert_response :forbidden
    
  end
 
  def test_delete
    #delete person with valid id
    delete :delete, { :user_id => people(:valid_person).id, :format => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success
    
    # Check that deleted user is really removed
    get :show, { :user_id => people(:valid_person).id, :format => 'json' }, { :session_id => sessions(:session4).id }
    assert_response :missing
    
    #try to delete person with invalid id
    delete :delete, { :user_id => -1, :format => 'json' }
    assert_response :missing
    
    #try to delete other user than self
    delete :delete, { :user_id => people(:contact).id, :format => 'json' },  { :session_id => sessions(:session4).id }
    assert_response :forbidden
    
  end
  
  def test_add_friend
    #add friend to a valid person (as a request at first)
    post :add_friend, { :user_id  => people(:valid_person).id, :friend_id => people(:not_yet_friend).id, :format  => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success
    
    # test that added friend request ís added correctly
    assert  assigns["person"].pending_contacts.include?(assigns["friend"])
    
    # add the friendship also in other direction == accept the request
    post :add_friend, { :user_id  => people(:not_yet_friend).id, :friend_id => people(:valid_person).id, :format  => 'json' },  { :session_id => sessions(:session3).id }
    assert_response :success
    
    # test that added friend ís added correctly
    assert  assigns["person"].contacts.include?(assigns["friend"])
    
  end
  
  def test_get_friends
    get :get_friends, { :user_id  => people(:valid_person).id, :format  => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success
    assert_not_nil assigns["person"]
    assert_not_nil assigns["friends"]
    assert_equal(assigns["person"].contacts, assigns["friends"])
    
  end
  
  def test_remove_friend
    #test that friendship exists both ways
    
    get :show, { :user_id => people(:valid_person).id, :format => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success
    assert_not_nil assigns["person"]
    user = assigns["person"]

    get :show, { :user_id => people(:friend).id, :format => 'json' }
    assert_response :success
    assert_not_nil assigns["person"]
    friend = assigns["person"]
    
    assert user.contacts.include?(friend)
    assert friend.contacts.include?(user)
    
    # breakup friendship
    delete :remove_friend, { :user_id => people(:valid_person).id, :friend_id => people(:friend).id, :format => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success
   
    #check that no more friends
    assert ! user.contacts.include?(friend)
    assert ! friend.contacts.include?(user)
    
    # - - - - - - - - - - - - - - - - - - - - - - - - - 
    #Same testing with a requested (not yet accepted) friend
    get :show, { :user_id => people(:requested).id, :format => 'json' }
    assert_response :success
    requested = assigns["person"]
    
    assert user.requested_contacts.include?(requested)
    assert requested.pending_contacts.include?(user)
    
    #Try to breakup from wrong firection (unauthorized)
    delete :remove_friend, { :user_id => people(:requested).id, :friend_id => people(:valid_person).id , :format => 'json' }
    assert_response :forbidden
    
    # breakup friendship
    delete :remove_friend, { :user_id => people(:valid_person).id, :friend_id => people(:requested).id, :format => 'json' }
    assert_response :success
    
    #check that no more requested
    assert ! user.requested_contacts.include?(requested)
    assert ! requested.pending_contacts.include?(user)
  end

  def test_search
    search("Matti")
    search("matti")
    search("Kuusinen")
    search("tti")
    search("Juho Makkonen")
    search("a")
    search("Juho.*onen", false)
    search("", false)
  end

  def test_routing
    with_options :controller => 'people', :format => 'json' do |test|
      test.assert_routing({ :method => 'post', :path => '/people' }, 
        { :action => 'create' })
      test.assert_routing({ :method => 'get', :path => '/people/hfr2kf38s7/@self' }, 
        { :action => 'show', :user_id => "hfr2kf38s7" })
      test.assert_routing({ :method => 'put', :path => '/people/hfr2kf38s7/@self' }, 
        { :action => 'update', :user_id => "hfr2kf38s7" })
      test.assert_routing({ :method => 'delete', :path => '/people/hfr2kf38s7/@self' }, 
        { :action => 'delete', :user_id => "hfr2kf38s7" })  
      test.assert_routing({ :method => 'get', :path => '/people/hfr2kf38s7/@friends' }, 
        { :action => 'get_friends', :user_id => "hfr2kf38s7" })
      test.assert_routing({ :method => 'post', :path => '/people/hfr2kf38s7/@friends' }, 
        { :action => 'add_friend', :user_id => "hfr2kf38s7" })
      test.assert_routing({ :method => 'delete', :path => '/people/hfr2kf38s7/@friends/f229f' }, 
        { :action => 'remove_friend', :user_id => "hfr2kf38s7", :friend_id => "f229f" })
    end
  end

  private 
  def search(search, should_find=true)
    get :index, { :format => 'json', :search => search }, { :session_id => sessions(:session1) }
    assert_response :success
    assert_not_nil assigns["people"]
    json = JSON.parse(@response.body)

    if not should_find
      assert_equal 0, json["entries"].length
      return
    end

    assert_not_equal 0, json["entries"].length, "Found nothing with '#{search}'"

    reg = Regexp.new(search.downcase.tr("*", ""))

    json["entries"].each do |person|
      assert_not_nil person["name"]
      assert person["name"]["unstructured"].downcase =~ reg
    end    
  end

end
