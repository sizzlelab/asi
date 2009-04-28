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
    
  def test_index
    # Should find nothing
    get :index, { :format => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success 
    assert_not_nil assigns(:people)
    json = JSON.parse(@response.body)
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
  
  def test_create
    # create valid user
    assert_nil(Session.find(sessions(:client_only_session).id).person_id)
    @emails = ActionMailer::Base.deliveries
    @emails.clear
    
    post :create, { :person => {:username  => "newbie", 
                    :password => "newbass",
                    :email => "newbie@testland.gov",
                    :consent => "FI1" }, 
                    :format => 'json'}, 
                  { :session_id => sessions(:client_only_session).id }
    assert_response :created 
    user = assigns["person"] 
    assert_not_nil user
    json = JSON.parse(@response.body)
    if VALIDATE_EMAILS
      assert_equal(1, @emails.length)
      assert_not_nil(user.pending_validation)
      assert_equal(user.id, user.pending_validation.person_id)
      mailtext = @emails[0].to_s

      # make sure that the activation link and username exists in email
      assert mailtext =~ /http\S+#{user.pending_validation.key}/
      assert mailtext =~ /#{user.username}/ 
    end
    assert_not_nil(Session.find(sessions(:client_only_session).id).person_id) 
    
        
    # check that the created user can be found
    created_user = Person.find_by_username("newbie")
    assert_equal created_user.username, user.username
    assert_equal created_user.consent, user.consent
  end

  def test_update
    # update valid user
    testing_email = "newemail@oldserv.er"
    put :update, { :user_id => people(:valid_person).id, :person => {:email => testing_email }, :format => 'json' }, 
                 { :session_id => sessions(:session1).id }
    
    json = JSON.parse(@response.body)
    assert_response :success

    # try to update the id
    put :update, { :user_id => people(:valid_person).id, :person => {:id => "9999" }, :format => 'json' }, 
                 { :session_id => sessions(:session1).id }
    assert_response :success
    json = JSON.parse(@response.body)
    assert_not_equal json["id"], "9999"

    # asserts for checking that the updates really stored correctly
    assert_equal(assigns["person"].email, testing_email)
    # assert that no changed value has not changed
    assert_equal(assigns["person"].username, people(:valid_person).username)
    
    # try to update other user than self
    put :update, { :user_id => people(:friend).id, :person => {:email => testing_email }, :format => 'json' }, 
                 { :session_id => sessions(:session1).id }
    assert_response :forbidden

    # update name 
    put :update, { :user_id => people(:valid_person).id, :person => { :name => { :given_name => "Joe" } }, :format => 'json' }, 
                 { :session_id => sessions(:session1).id }
    assert_response :success
    assert_equal("Joe", assigns["person"].name.given_name)
    json = JSON.parse(@response.body)
    
    put :update, { :user_id => people(:valid_person).id, :person => { :address => { :street_address => "Jämeräntaival" } }, :format => 'json' }, 
                 { :session_id => sessions(:session1).id }
    assert_response :success
    assert_equal("Jämeräntaival", assigns["person"].address.street_address)
    json = JSON.parse(@response.body)
    
    #try to update too long name 
    put :update, { :user_id => people(:valid_person).id, :person => { :name => { :family_name => "Joeboyloloasdugesknfdsfuesfsdfnsudkfsndfnusaa" } }, :format => 'json' }, 
                 { :session_id => sessions(:session1).id }
    assert_response :bad_request
    json = JSON.parse(@response.body)
    
    #try to update too long phone number 
    put :update, { :user_id => people(:valid_person).id, :person => { :phone_number => "123456789012345678901234567890" }, :format => 'json' }, 
                 { :session_id => sessions(:session1).id }
    assert_response :bad_request
    #assert_not_equal("Joeboyloloasdugesknfdsfuesfsdfnsudkfsndfnusaa", assigns["person"].name.given_name)
    json = JSON.parse(@response.body)
   # puts json
    

    # try to update with too long given name
    put :update, { 
                   :user_id => people(:valid_person).id, 
                   :person => { 
                     :name => { :given_name => "JoeJoeJoeJoeJoeJoeJoeJoeJoeJoeJoe" } 
                   }, 
                   :format => 'json' 
                 }, 
                 { :session_id => sessions(:session1).id }
    assert_response :bad_request
    json = JSON.parse(@response.body)
    

    # update status_message
    test_status = "Testing hard..."
    put :update, { :user_id => people(:valid_person).id, :person => { :status_message =>  test_status  }, :format => 'json' }, 
                 { :session_id => sessions(:session1).id }
    assert_response :success
    assert_equal(test_status, assigns["person"].person_spec.status_message)
    json = JSON.parse(@response.body)
    # check that same status message is returned with show
    get :show, { :user_id => people(:valid_person).id, :format => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success
    json = JSON.parse(@response.body)
    assert_equal test_status, json["status"]["message"]
  
    # Check that updating the name doesn't delete old values
    put :update, { :user_id => people(:valid_person).id, :person => { :name => { :family_name => "Doe" } }, :format => 'json' }, 
                 { :session_id => sessions(:session1).id }
    assert_response :success
    assert_equal("Joe", assigns["person"].name.given_name)
    assert_equal("Doe", assigns["person"].name.family_name)
    json = JSON.parse(@response.body)
    
    # update birthdate
    valid_date = "1945-12-24"
    invalid_dates = ["asdasdasdasdfasf", "1999-11-111", "1999-31-31"]
    put :update, { :user_id => people(:valid_person).id, :person => { :birthdate =>  valid_date  }, :format => 'json' }, 
                 { :session_id => sessions(:session1).id }
    assert_response :success, @response.body
    get :show, { :user_id => people(:valid_person).id, :format => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success
    json = JSON.parse(@response.body)
    assert_equal valid_date, json["birthdate"]
    #try invalid dates
    invalid_dates.each do |birthdate|
      put :update, { :user_id => people(:valid_person).id, :person => { :birthdate =>  birthdate  }, :format => 'json' }, 
                   { :session_id => sessions(:session1).id }
      assert_response :bad_request
      #check that stored date didn't change
      get :show, { :user_id => people(:valid_person).id, :format => 'json' }, { :session_id => sessions(:session1).id }
      assert_response :success
      json = JSON.parse(@response.body)
      assert_equal valid_date, json["birthdate"]                  
    end  
  end
  
  def test_update_invalid_email
      invalid_email = "newemail(at)oldserv.er"
      put :update, { :user_id => people(:valid_person).id, :person => {:email => invalid_email }, :format => 'json' }, 
                   { :session_id => sessions(:session1).id }  
      assert_response :bad_request
      json = JSON.parse(@response.body)
      assert json.to_s =~ /email/i && json.to_s =~ /invalid/i
  end
  
  def test_delete    
    #delete person with valid id
    delete :delete, { :user_id => people(:valid_person).id, :format => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success
    json = JSON.parse(@response.body)
    
    # Check that deleted user is really removed
    get :show, { :user_id => people(:valid_person).id, :format => 'json' }, { :session_id => sessions(:session4).id }
    assert_response :missing
    
    # Check that related objects are removed also
    assert Connection.find(:all, :conditions => { :person_id =>  people(:valid_person).id}).empty?
    assert PersonSpec.find(:all, :conditions => { :person_id =>  people(:valid_person).id}).empty?
    assert PersonName.find(:all, :conditions => { :person_id =>  people(:valid_person).id}).empty?
    assert Location.find(:all, :conditions => { :person_id =>  people(:valid_person).id}).empty?
    
    
    #try to delete person with invalid id
    delete :delete, { :user_id => -1, :format => 'json' }
    assert_response :missing
    
    #try to delete other user than self
    delete :delete, { :user_id => people(:contact).id, :format => 'json' },  { :session_id => sessions(:session4).id }
    assert_response :forbidden
    
  end
  
  def test_update_and_get_avatar
    # try to show the default large thumbnail
    get :get_large_thumbnail, { :user_id => people(:valid_person).id, :format => 'jpg' }, { :session_id => sessions(:session1).id }
    assert_response :success
    
    # try to show the default small thumbnail
    get :get_small_thumbnail, { :user_id => people(:valid_person).id, :format => 'jpg' }, { :session_id => sessions(:session1).id }
    assert_response :success
    
    # try to upload an avatar
    put :update_avatar, { :user_id => people(:valid_person).id, :file => fixture_file_upload("Australian_painted_lady.jpg","image/jpeg"),
                          :format => 'html' }, 
                        { :session_id => sessions(:session1).id }                 
    assert_response :success
    
    # try to show the uploaded avatar
    get :get_avatar, { :user_id => people(:valid_person).id, :format => 'jpg' }, { :session_id => sessions(:session1).id }
    assert_response :success
    
    # try to show the large thumbnail of the avatar
    get :get_large_thumbnail, { :user_id => people(:valid_person).id, :format => 'jpg' }, { :session_id => sessions(:session1).id }
    assert_response :success
    
    # try to show the small thumbnail of the avatar
    get :get_small_thumbnail, { :user_id => people(:valid_person).id, :format => 'jpg' }, { :session_id => sessions(:session1).id }
    assert_response :success
    
    # check that avatar info is changed to 'set'
    get :show, { :user_id => people(:valid_person).id, :format => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_equal("set", json["avatar"]["status"])

  end
  
  def test_delete_avatar
    #delete person with valid id
    delete :delete_avatar, { :user_id => people(:valid_person).id, :format => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success
    json = JSON.parse(@response.body)  
  end
  
  def test_add_friend
    #add friend to a valid person (as a request at first)
    post :add_friend, { :user_id  => people(:valid_person).id, :friend_id => people(:not_yet_friend).id, :format  => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success
    json = JSON.parse(@response.body)
    
    # test that added friend request ís added correctly
    assert  assigns["person"].requested_contacts.include?(assigns["friend"])
    
    # add the friendship also in other direction == accept the request
    post :add_friend, { :user_id  => people(:not_yet_friend).id, :friend_id => people(:valid_person).id, :format  => 'json' },  { :session_id => sessions(:session3).id }
    assert_response :success
    json = JSON.parse(@response.body)
    
    # test that added friend ís added correctly
    assert assigns["person"].contacts.include?(assigns["friend"])
    
  end
  
  def test_get_friends_in_order
    # check that statusmessage change dates exist and are in right order
    assert people(:friend).person_spec.status_message_changed > people(:invalid_person).person_spec.status_message_changed,
                  "Statusmessages in fixtures are not in the order that the test would expect."
    
    get :get_friends, { :user_id  => people(:valid_person).id, :format  => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success
    assert_not_nil assigns["person"]
    assert_not_nil assigns["friends"]
    assert_equal(assigns["person"].contacts, assigns["friends"])
    json = JSON.parse(@response.body)
    assert_equal people(:invalid_person).username, json["entry"][0]["username"]
    assert_equal people(:friend).username, json["entry"][1]["username"]
    
    # Check that the order is reversed because of the sorting parameters.
    get :get_friends, { :user_id  => people(:valid_person).id, :sortBy => "status_changed",
                        :sortOrder => "descending", :format  => 'json' }, 
                        { :session_id => sessions(:session1).id }
    assert_response :success
    assert_not_nil assigns["person"]
    assert_not_nil assigns["friends"]
    #assert_equal(assigns["person"].contacts, assigns["friends"])
    json = JSON.parse(@response.body)  
    assert_equal people(:friend).username, json["entry"][0]["username"]
    assert_equal people(:invalid_person).username, json["entry"][1]["username"]    
  end
  
  def test_remove_friend
    #test that friendship exists both ways
    
    get :show, { :user_id => people(:valid_person).id, :format => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success
    assert_not_nil assigns["person"]
    user = assigns["person"]
    json = JSON.parse(@response.body)

    get :show, { :user_id => people(:friend).id, :format => 'json' }
    assert_response :success
    assert_not_nil assigns["person"]
    friend = assigns["person"]
    json = JSON.parse(@response.body)
    
    assert user.contacts.include?(friend)
    assert friend.contacts.include?(user)
    
    # breakup friendship
    delete :remove_friend, { :user_id => people(:valid_person).id, :friend_id => people(:friend).id, :format => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success
    json = JSON.parse(@response.body)
   
    #check that no more friends
    assert ! user.contacts.include?(friend)
    assert ! friend.contacts.include?(user)
    
    # - - - - - - - - - - - - - - - - - - - - - - - - - 
    #Same testing with a requested (not yet accepted) friend
    get :show, { :user_id => people(:requested).id, :format => 'json' }
    assert_response :success
    requested = assigns["person"]
    json = JSON.parse(@response.body)
    
    assert user.requested_contacts.include?(requested)
    assert requested.pending_contacts.include?(user)
    
    #Try to breakup from wrong firection (unauthorized)
    delete :remove_friend, { :user_id => people(:requested).id, :friend_id => people(:valid_person).id , :format => 'json' }
    assert_response :forbidden
    
    # breakup friendship
    delete :remove_friend, { :user_id => people(:valid_person).id, :friend_id => people(:requested).id, :format => 'json' }
    assert_response :success
    json = JSON.parse(@response.body)
    
    #check that no more requested
    assert ! user.pending_contacts.include?(requested)
    assert ! requested.requested_contacts.include?(user)
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
    search("stephen")
    search("Liimatta")
  end
  
  def test_routing
    user_id = "hfr2kf38s7"

    with_options :controller => "people", :format => "json" do |test|
      test.assert_routing({ :method => "post", :path => "/people" }, 
        { :action => "create" })
      test.assert_routing({ :method => "get", :path => "/people/#{user_id}/@self" }, 
        { :action => "show", :user_id => user_id })
      test.assert_routing({ :method => "put", :path => "/people/#{user_id}/@self" }, 
        { :action => "update", :user_id => user_id })
      test.assert_routing({ :method => "delete", :path => "/people/#{user_id}/@self" }, 
        { :action => "delete", :user_id => user_id })  
      test.assert_routing({ :method => "get", :path => "/people/#{user_id}/@friends" }, 
        { :action => "get_friends", :user_id => user_id })
      test.assert_routing({ :method => "post", :path => "/people/#{user_id}/@friends" }, 
        { :action => "add_friend", :user_id => user_id })
      test.assert_routing({ :method => "delete", :path => "/people/#{user_id}/@friends/f229f" }, 
        { :action => "remove_friend", :user_id => user_id, :friend_id => "f229f" })
    end
  end

  def test_pending_contacts
    person = people(:requested)
    get :pending_friend_requests, { :user_id => person.id, :format => 'json' }, { :session_id => sessions(:session5) }
    assert_response :success
    json = JSON.parse(@response.body)
    assert json.size > 0
    json["entry"].each do |p|
      contact = Person.find_by_id(p["id"])
      assert person.pending_contacts.include?(contact)
    end
  end
  
  def test_reject_pending_contact
    person = people(:requested)
    assert !person.pending_contacts.empty?
    delete :reject_friend_request, { :user_id => person.id, :friend_id => people(:valid_person).id,  :format => 'json' }, 
                                   { :session_id => sessions(:session5) }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert person.pending_contacts.empty?
  end
  
  def test_response_content_type
      get :index, {:format => 'json', :search => "test"}, { :session_id => sessions(:session1) }
      assert_equal 'application/json', @response.content_type
      
  end
  
  # Password validations are not performed in the normal way because it is not stored in clear text
  # in the model. Here is checked that creating or updating doesn't succeed with invalid password.
  def test_password_constraints
    
    too_short_password = "shw"
    too_long_password = "abcdefghijklmnopq"
    # Try to create user with too short password
    post :create, { :person => {:username  => "failer", 
                    :password => too_short_password,
                    :email => "failer@example.gov",
                    :consent => "FI1" }, 
                    :format => 'json'}, 
                  { :session_id => sessions(:client_only_session).id }
    assert_response :bad_request 
    json = JSON.parse(@response.body)
    assert_nil assigns["person"] 
    assert_equal("[\"Password is too short\"]", @response.body)
    
    # Try to create user with too long password
    post :create, { :person => {:username  => "failer", 
                    :password => too_long_password,
                    :email => "failer@example.gov",
                    :consent => "FI1" }, 
                    :format => 'json'}, 
                  { :session_id => sessions(:client_only_session).id }
    assert_response :bad_request 
    json = JSON.parse(@response.body)
    assert_nil assigns["person"] 
    assert_equal("[\"Password is too long\"]", @response.body)
    
    # Try to update valid users password to too short
    encrypted_password = people(:valid_person).encrypted_password
    put :update, { :user_id => people(:valid_person).id, :person => { :password =>too_short_password }, :format => 'json' }, 
                 { :session_id => sessions(:session1).id }
    assert_response :bad_request
    assert_equal("[\"Password is too short\"]", @response.body)
    
    #check that the stored password was not changed
    assert_equal(encrypted_password, Person.find(people(:valid_person).id).encrypted_password)
    json = JSON.parse(@response.body)
    

    # Try to update valid users password to too long 
    encrypted_password = people(:valid_person).encrypted_password
    put :update, { :user_id => people(:valid_person).id, :person => { :password =>too_long_password }, :format => 'json' }, 
                 { :session_id => sessions(:session1).id }
    assert_response :bad_request
    assert_equal("[\"Password is too long\"]", @response.body)
    
    #check that the stored password was not changed
    assert_equal(encrypted_password, Person.find(people(:valid_person).id).encrypted_password)
    json = JSON.parse(@response.body)   
  end
  
  private 
  
  def search(search, should_find=true)
    get :index, { :format => 'json', :search => search }, { :session_id => sessions(:session1) }
    assert_response :success
    assert_not_nil assigns["people"]
    json = JSON.parse(@response.body)

    if not should_find
      assert_equal 0, json["entry"].length
      return
    end

    assert_not_equal 0, json["entry"].length, "Found nothing with '#{search}'"

    reg = Regexp.new(search.downcase.tr("*", ""))

    json["entry"].each do |person|
      assert_not_nil person["name"]
      assert person["name"]["unstructured"].downcase =~ reg
      assert_not_nil(person["connection"])
      if (Person.find(sessions(:session1).person_id).contacts.include?(Person.find(person["id"])))
        assert_equal("friend", person["connection"]  )
      elsif (Person.find(sessions(:session1).person_id).pending_contacts.include?(Person.find(person["id"])))
        assert_equal("pending", person["connection"]  )
      elsif (Person.find(sessions(:session1).person_id).requested_contacts.include?(Person.find(person["id"])))
        assert_equal("requested", person["connection"]  )
      elsif (sessions(:session1).person_id == person["id"])
        assert_equal("you", person["connection"]  )
      else
        assert_equal("none", person["connection"]  )
      end
    end    
  end
end
