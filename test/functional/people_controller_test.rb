# -*- coding: iso-8859-1 -*-
require 'test_helper'
require 'json'

class PeopleControllerTest < ActionController::TestCase
  fixtures :sessions, :people
  

  VALID_PERSON_JSON = '
  {"address":{"street_address":"MyString","postal_code":"MyString","unstructured":"MyString, MyString MyString","locality":"MyString"},"name":{"unstructured":"Juho Makkonen","family_name":"Makkonen","given_name":"Juho"},"birthdate":null,"connection":"you","is_association":null,"role":"user","username":"kusti","gender":{"displayvalue":null,"key":null},"avatar":{"status":"not_set","link":{"rel":"self","href":"\\/people\\/1\\/@avatar"}},"id":"1","phone_number":null,"msn_nick":null,"website":null,"location":{"updated_at":"2008-07-11T12:36:33Z","label":"Otaniemen Alepa","accuracy":58.0,"latitude":60.163389841749,"longitude":24.857125767506},"irc_nick":null,"description":null,"status":{"changed":null,"message":""},"email":"working@address.com"}
'

  def setup
    @controller = PeopleController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end

  def test_index
    get :index, { :format => 'json' }, { :cos_session_id => sessions(:session1).id }
    assert_response :success
    json = JSON.parse(@response.body)
    assert_equal Person.count, json["entry"].size
  end

  def test_show
    login_as people(:valid_person)
    get :show, { :user_id => people(:valid_person).guid, :format => 'json' }
    assert_response :success
    assert_not_nil assigns["person"]
    json = JSON.parse(@response.body)

    assert_equal people(:valid_person).guid, json["entry"]["id"]
    assert_nil json["entry"]["password"]

    assert_equal "you", json["entry"]["connection"]

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
                  { :cos_session_id => sessions(:client_only_session).id }
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

    #make sure that the  welcome mail is sent
    assert !ActionMailer::Base.deliveries.empty?
    mail = ActionMailer::Base.deliveries.first

    assert_equal([APP_CONFIG.asi_mail_from_address], mail.from)
    assert_equal([user.email], mail.to)
    #assert_equal("Tervetuloa #{clients(:one).realname || clients(:one).name}-käyttäjäksi! | Welcome to #{clients(:one).realname || clients(:one).name}!", mail.subject)

    assert_not_nil(Session.find(sessions(:client_only_session).id).person_id)

    assert_not_nil json["entry"]
    assert_not_nil json["entry"]["id"]
    assert json["entry"]["id"].length > 5, "New guid was '#{json["entry"]["id"]}'"

    # check that the created user can be found
    created_user = Person.find_by_username("newbie")
    assert_equal created_user.username, user.username
    assert_equal created_user.consent, user.consent
  end

  def test_create_association
    assert_nil(Session.find(sessions(:client_only_session).id).person_id)
    ActionMailer::Base.deliveries.clear

    post :create, { :person => {:username  => "newbie",
                    :password => "newbass",
                    :email => "newbie@testland.gov",
                    :consent => "FI1",
                    :is_association => "true"},
                    :format => 'json',
                    :welcome_email => "false"},
                  { :cos_session_id => sessions(:client_only_session).id }
    assert_response :created
    user = assigns["person"]
    assert_not_nil user
    json = JSON.parse(@response.body)
    assert_not_nil(Session.find(sessions(:client_only_session).id).person_id)

    #check that no welcome mail is sent
    assert ActionMailer::Base.deliveries.empty?, "No welcome email should have been sent."

    # check that the created user can be found
    created_user = Person.find_by_username("newbie")
    assert_equal created_user.username, user.username
    assert_equal created_user.consent, user.consent
    assert user.association?
  end

  def test_recover_password
    ActionMailer::Base.deliveries.clear

    #Testing invalid email address
    post :recover_password, { :format => 'json', :email => "not@found"},
                            { :cos_session_id => sessions(:client_only_session).id}

    assert ActionMailer::Base.deliveries.empty?, "Testing that no email is sent."
    assert_response :not_found, "Testing that no record is found"


    #testing password changing
    person = people(:valid_person)
    post :recover_password, { :format => 'json', :email => person.email},
                            { :cos_session_id => sessions(:client_only_session).id}

    assert !ActionMailer::Base.deliveries.empty?

    mail = ActionMailer::Base.deliveries.first

    id = mail.body[/id=(.*)/, 1]

    get :reset_password, { :format => 'html', :id => id },
                         { :cos_session_id => sessions(:client_only_session).id}
    assert_response :ok, 'Testing that form page is successfully opened.'

    post :change_password, { :format => 'html', :id => id,
                             :password => 'testing', :confirm_password => 'testing'},
                           { :cos_session_id => sessions(:client_only_session).id}
    assert_response :ok, 'Testing if password is succesfully changed.'

    post :change_password, { :format => 'html', :id => id,
                             :password => 'testing', :confirm_password =>'testing'},
                           { :cos_session_id => sessions(:client_only_session).id}
    assert_response :unauthorized, "Testing that id works only once, and invalid id's are not accepted"

    post :change_password, { :format => 'html',
                             :password => 'testing', :confirm_password =>'testing'},
                           { :cos_session_id => sessions(:client_only_session).id}
    assert_response :unauthorized, "Testing that empty id is not accepted"

    #fetching new id and testing with invalid password combinations
    ActionMailer::Base.deliveries.clear

    post :recover_password, { :format => 'json', :email => person.email},
                            { :cos_session_id => sessions(:client_only_session).id}

    assert !ActionMailer::Base.deliveries.empty?

    mail = ActionMailer::Base.deliveries.first
    id = mail.body[/id=(.*)/, 1]

    { "password" => "pass" , "o" => "o", "" => "" }.each do |password, confirm_password|
      post :change_password, { :format => 'html', :id => id,
                               :password => password, :confirm_password => confirm_password},
                             { :cos_session_id => sessions(:client_only_session).id}
      assert_redirected_to("/people/reset_password?id=#{id}",
                           "Testing invalid password combinations. Password: #{password}, Confirmation: #{confirm_password}")
    end
  end

  def test_update
    # update valid user
    testing_email = "newemail@oldserv.er"
    put :update, { :user_id => people(:valid_person).guid, :person => {:email => testing_email }, :format => 'json' },
                 { :cos_session_id => sessions(:session1).id }

    json = JSON.parse(@response.body)
    assert_response :success

    # try to update the id
    put :update, { :user_id => people(:valid_person).guid, :person => {:id => "9999" }, :format => 'json' },
                 { :cos_session_id => sessions(:session1).id }
    assert_response :success
    json = JSON.parse(@response.body)
    assert_not_equal json["entry"]["id"], "9999"

    # asserts for checking that the updates really stored correctly
    assert_equal(assigns["person"].email, testing_email)
    # assert that no changed value has not changed
    assert_equal(assigns["person"].username, people(:valid_person).username)

    # try to update other user than self
    put :update, { :user_id => people(:friend).guid, :person => {:email => testing_email }, :format => 'json' },
                 { :cos_session_id => sessions(:session1).id }
    assert_response :forbidden

    # update name
    put :update, { :user_id => people(:valid_person).guid, :person => { :name => { :given_name => "Joe" } }, :format => 'json' },
                 { :cos_session_id => sessions(:session1).id }
    assert_response :success
    assert_equal("Joe", assigns["person"].name.given_name)
    json = JSON.parse(@response.body)

    put :update, { :user_id => people(:valid_person).guid, :person => { :address => { :street_address => "JÃ¤merÃ¤ntaival" } }, :format => 'json' },
                 { :cos_session_id => sessions(:session1).id }
    assert_response :success
    assert_equal("JÃ¤merÃ¤ntaival", assigns["person"].address.street_address)
    json = JSON.parse(@response.body)

    #try to update too long name
    put :update, { :user_id => people(:valid_person).guid, :person => { :name => { :family_name => "Joeboyloloasdugesknfdsfuesfsdfnsudkfsndfnusaa" } }, :format => 'json' },
                 { :cos_session_id => sessions(:session1).id }
    assert_response :bad_request
    json = JSON.parse(@response.body)

    #try to update too long phone number
    put :update, { :user_id => people(:valid_person).guid, :person => { :phone_number => "123456789012345678901234567890" }, :format => 'json' },
                 { :cos_session_id => sessions(:session1).id }
    assert_response :bad_request
    #assert_not_equal("Joeboyloloasdugesknfdsfuesfsdfnsudkfsndfnusaa", assigns["person"].name.given_name)
    json = JSON.parse(@response.body)
   # puts json


    # try to update with too long given name
    put :update, {
                   :user_id => people(:valid_person).guid,
                   :person => {
                     :name => { :given_name => "JoeJoeJoeJoeJoeJoeJoeJoeJoeJoeJoe" }
                   },
                   :format => 'json'
                 },
                 { :cos_session_id => sessions(:session1).id }
    assert_response :bad_request
    json = JSON.parse(@response.body)


    # update status_message
    test_status = "Testing hard..."
    put :update, { :user_id => people(:valid_person).guid, :person => { :status_message =>  test_status  }, :format => 'json' },
                 { :cos_session_id => sessions(:session1).id }
    assert_response :success
    assert_equal(test_status, assigns["person"].status_message)
    json = JSON.parse(@response.body)
    # check that same status message is returned with show
    get :show, { :user_id => people(:valid_person).guid, :format => 'json' }, { :cos_session_id => sessions(:session1).id }
    assert_response :success
    json = JSON.parse(@response.body)
    assert_equal test_status, json["entry"]["status"]["message"]

    # Check that updating the name doesn't delete old values
    put :update, { :user_id => people(:valid_person).guid, :person => { :name => { :family_name => "Doe" } }, :format => 'json' },
                 { :cos_session_id => sessions(:session1).id }
    assert_response :success
    assert_equal("Joe", assigns["person"].name.given_name)
    assert_equal("Doe", assigns["person"].name.family_name)
    json = JSON.parse(@response.body)

    # update birthdate
    valid_date = "1945-12-24"
    invalid_dates = ["asdasdasdasdfasf", "1999-11-111", "1999-31-31"]
    put :update, { :user_id => people(:valid_person).guid, :person => { :birthdate =>  valid_date  }, :format => 'json' },
                 { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    get :show, { :user_id => people(:valid_person).guid, :format => 'json' }, { :cos_session_id => sessions(:session1).id }
    assert_response :success
    json = JSON.parse(@response.body)
    assert_equal valid_date, json["entry"]["birthdate"]
    #try invalid dates
    invalid_dates.each do |birthdate|
      put :update, { :user_id => people(:valid_person).guid, :person => { :birthdate =>  birthdate  }, :format => 'json' },
                   { :cos_session_id => sessions(:session1).id }
      assert_response :bad_request
      #check that stored date didn't change
      get :show, { :user_id => people(:valid_person).guid, :format => 'json' }, { :cos_session_id => sessions(:session1).id }
      assert_response :success
      json = JSON.parse(@response.body)
      assert_equal valid_date, json["entry"]["birthdate"]
    end
  end

  def test_mass_assignment
    login_as people(:valid_person)
    put :update, { :user_id => people(:valid_person).guid, :person => { :guid => "booX" }, :format => 'json' }
    assert_response :success
    assert_not_equal "booX", @json["entry"]["id"]
  end


  def test_update_invalid_email
    invalid_email = "newemail(at)oldserv.er"
    put :update, { :user_id => people(:valid_person).guid, :person => {:email => invalid_email }, :format => 'json' },
                 { :cos_session_id => sessions(:session1).id }
    assert_response :bad_request
    json = JSON.parse(@response.body)
    assert json.to_s =~ /email/i && json.to_s =~ /invalid/i
  end

  def test_update_invalid_email
    put :update, { :user_id => people(:valid_person).guid, :person => {:email2 => "foo" }, :format => 'json' },
                 { :cos_session_id => sessions(:session1).id }
    assert_response :bad_request
    json = JSON.parse(@response.body)
  end


  def test_delete
    #delete person with valid id
    delete :delete, { :user_id => people(:valid_person).guid, :format => 'json' }, { :cos_session_id => sessions(:session1).id }
    assert_response :success
    json = JSON.parse(@response.body)

    # Check that deleted user is really removed
    get :show, { :user_id => people(:valid_person).guid, :format => 'json' }, { :cos_session_id => sessions(:session4).id }
    assert_response :missing

    # Check that related objects are removed also
    assert Connection.find(:all, :conditions => { :person_id =>  people(:valid_person).id}).empty?
    assert PersonName.find(:all, :conditions => { :person_id =>  people(:valid_person).id}).empty?
    assert Location.find(:all, :conditions => { :person_id =>  people(:valid_person).id}).empty?


    #try to delete person with invalid id
    delete :delete, { :user_id => -1, :format => 'json' }
    assert_response :missing

    #try to delete other user than self
    delete :delete, { :user_id => people(:contact).guid, :format => 'json' },  { :cos_session_id => sessions(:session4).id }
    assert_response :forbidden

  end


  def test_add_friend
    #add friend to a valid person (as a request at first)
    post :add_friend, { :user_id  => people(:valid_person).guid, :friend_id => people(:not_yet_friend).guid, :format  => 'json' }, { :cos_session_id => sessions(:session1).id }
    assert_response :success
    json = JSON.parse(@response.body)

    # test that added friend request Ã­s added correctly
    assert  assigns["person"].requested_contacts.include?(assigns["friend"])

    # add the friendship also in other direction == accept the request
    post :add_friend, { :user_id  => people(:not_yet_friend).guid, :friend_id => people(:valid_person).guid, :format  => 'json' },  { :cos_session_id => sessions(:session3).id }
    assert_response :success
    json = JSON.parse(@response.body)

    # test that added friend Ã­s added correctly
    assert assigns["person"].contacts.include?(assigns["friend"])

  end

  def test_get_friends_in_order
    # check that statusmessage change dates exist and are in right order
    assert people(:friend).status_message_changed > people(:invalid_person).status_message_changed,
                  "Statusmessages in fixtures are not in the order that the test would expect."

    get :get_friends, { :user_id  => people(:valid_person).guid, :format  => 'json' }, { :cos_session_id => sessions(:session1).id }
    assert_response :success
    assert_not_nil assigns["person"]
    assert_not_nil assigns["friends"]
    assert_equal(assigns["person"].contacts, assigns["friends"])
    json = JSON.parse(@response.body)
    assert_equal people(:invalid_person).username, json["entry"][0]["username"]
    assert_equal people(:friend).username, json["entry"][1]["username"]

    # Check that the order is reversed because of the sorting parameters.
    get :get_friends, { :user_id  => people(:valid_person).guid, :sortBy => "status_changed",
                        :sortOrder => "descending", :format  => 'json' },
                        { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    assert_not_nil assigns["person"]
    assert_not_nil assigns["friends"]
    #assert_equal(assigns["person"].contacts, assigns["friends"])
    json = JSON.parse(@response.body)
    assert_equal people(:friend).username, json["entry"][0]["username"]
    assert_equal people(:invalid_person).username, json["entry"][1]["username"]
  end

  def test_remove_friend
    #test that friendship exists both ways

    get :show, { :user_id => people(:valid_person).guid, :format => 'json' }, { :cos_session_id => sessions(:session1).id }
    assert_response :success
    assert_not_nil assigns["person"]
    user = assigns["person"]
    json = JSON.parse(@response.body)

    get :show, { :user_id => people(:friend).guid, :format => 'json' }
    assert_response :success
    assert_not_nil assigns["person"]
    friend = assigns["person"]
    json = JSON.parse(@response.body)

    assert user.contacts.include?(friend)
    assert friend.contacts.include?(user)

    # breakup friendship
    delete :remove_friend, { :user_id => people(:valid_person).guid, :friend_id => people(:friend).guid, :format => 'json' }, { :cos_session_id => sessions(:session1).id }
    assert_response :success
    json = JSON.parse(@response.body)

    #check that no more friends
    assert ! user.contacts.include?(friend)
    assert ! friend.contacts.include?(user)

    # - - - - - - - - - - - - - - - - - - - - - - - - -
    #Same testing with a requested (not yet accepted) friend
    get :show, { :user_id => people(:requested).guid, :format => 'json' }
    assert_response :success
    requested = assigns["person"]
    json = JSON.parse(@response.body)

    assert user.requested_contacts.include?(requested)
    assert requested.pending_contacts.include?(user)

    #Try to breakup from wrong firection (unauthorized)
    delete :remove_friend, { :user_id => people(:requested).guid, :friend_id => people(:valid_person).guid , :format => 'json' }
    assert_response :forbidden

    # breakup friendship
    delete :remove_friend, { :user_id => people(:valid_person).guid, :friend_id => people(:requested).guid, :format => 'json' }
    assert_response :success
    json = JSON.parse(@response.body)

    #check that no more requested
    assert ! user.pending_contacts.include?(requested)
    assert ! requested.requested_contacts.include?(user)

    delete :remove_friend, { :user_id => people(:valid_person).guid, :friend_id => people(:requested).guid, :format => 'json' }
    assert_response :not_found
    json = JSON.parse(@response.body)
  end

  def test_search
    Person.all.each do |p|
      search(p.name.unstructured) if p.name
    end
    search("Matti")
    search("matti")
    search("Kuusinen")
    search("tti")
    search("Juho Makkonen")
    search("a")
    search("Juho*onen", false)
    search("", false)
    search("Juho")
    search("Stephen")
    search("Liimatta")
    search("sepi")
    search("sepi-jaakko")
    search("Sepi-Jaakko Seutula")
    search("\"Juho Makkonen\"")
    search("te")
    search("kusti")
    #search("Järnö Törnävä") # Latin-1
  end
  
  def test_search_by_phone_number
    # normal case, should be found
    number = people(:valid_person).phone_number
    get :index, {:phone_number => number, :format => 'json' }, { :cos_session_id => sessions(:session1).id }
    assert_response :success
    json = JSON.parse(@response.body)
    assert_not_nil(json["entry"][0])
    assert_equal people(:valid_person).username, json["entry"][0]["username"]
    
    # search without the "+" in front, should be found
    number.gsub!("+", "")
    get :index, {:phone_number => number, :format => 'json' }, { :cos_session_id => sessions(:session1).id }
    assert_response :success
    json = JSON.parse(@response.body)
    assert_not_nil(json["entry"][0])
    assert_equal people(:valid_person).username, json["entry"][0]["username"]
    
    
    
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
    get :pending_friend_requests, { :user_id => person.guid, :format => 'json' }, { :cos_session_id => sessions(:session5) }
    assert_response :success
    json = JSON.parse(@response.body)
    assert json.size > 0
    json["entry"].each do |p|
      contact = Person.find_by_guid(p["id"])
      assert person.pending_contacts.include?(contact)
    end
  end

  def test_reject_pending_contact
    person = people(:requested)
    assert !person.pending_contacts.empty?
    delete :reject_friend_request, { :user_id => person.guid, :friend_id => people(:valid_person).guid,  :format => 'json' },
                                   { :cos_session_id => sessions(:session5) }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert person.pending_contacts.empty?
  end

  def test_response_content_type
      get :index, {:format => 'json', :search => "test"}, { :cos_session_id => sessions(:session1) }
      assert_equal 'application/json', @response.content_type

  end

  # Password validations are not performed in the normal way because it is not stored in clear text
  # in the model. Here is checked that creating or updating doesn't succeed with invalid password.
  def test_password_constraints

    too_short_password = "shw"
    too_long_password = ""
    300.times { too_long_password << 'a'}
    # Try to create user with too short password
    post :create, { :person => {:username  => "failer",
                    :password => too_short_password,
                    :email => "failer@example.gov",
                    :consent => "FI1" },
                    :format => 'json'},
                  { :cos_session_id => sessions(:client_only_session).id }
    assert_response :bad_request
    json = JSON.parse(@response.body)
    assert_nil assigns["person"]

    # Try to create user with too long password
    post :create, { :person => {:username  => "failer",
                    :password => too_long_password,
                    :email => "failer@example.gov",
                    :consent => "FI1" },
                    :format => 'json'},
                  { :cos_session_id => sessions(:client_only_session).id }
    assert_response :bad_request
    json = JSON.parse(@response.body)
    assert_nil assigns["person"]

    # Try to update valid users password to too short
    encrypted_password = people(:valid_person).encrypted_password
    put :update, { :user_id => people(:valid_person).guid, :person => { :password =>too_short_password }, :format => 'json' },
                 { :cos_session_id => sessions(:session1).id }
    assert_response :bad_request

    #check that the stored password was not changed
    assert_equal(encrypted_password, Person.find(people(:valid_person).id).encrypted_password)
    json = JSON.parse(@response.body)


    # Try to update valid users password to too long
    encrypted_password = people(:valid_person).encrypted_password
    put :update, { :user_id => people(:valid_person).guid, :person => { :password =>too_long_password }, :format => 'json' },
                 { :cos_session_id => sessions(:session1).id }
    assert_response :bad_request

    #check that the stored password was not changed
    assert_equal(encrypted_password, Person.find(people(:valid_person).id).encrypted_password)
    json = JSON.parse(@response.body)
  end

  def test_association_friendship
    login_as people(:valid_association), clients(:one)
    post :add_friend, { :user_id  => people(:valid_association).guid, :friend_id => people(:not_yet_friend).guid, :format  => 'json' }
    assert_response :bad_request

    post :add_friend, { :user_id  => people(:valid_person).guid, :friend_id => people(:valid_association).guid, :format  => 'json' }, { :cos_session_id => sessions(:session1).id }
    assert_response :bad_request
    json = JSON.parse(@response.body)
  end

  def test_orphan_search
    login
    get :index, { :search => "orphan", :format => "json" }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_equal [], json["entry"]
  end

  def test_kassi_email_kludge
    client = clients(:kassi)
    client.show_email = true

    login_as people(:valid_person).contacts[0], client
    get :show, { :user_id => people(:valid_person).guid, :format => "json"}
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_equal people(:valid_person).email, json["entry"]["email"]
  end
  
  # ASI only gives profile details to those client applications from which the user has logged in (i.e. role exists)
  def test_profile_info_filtering
    
    # Should show profile details when role exists
    login_as people(:valid_person), clients(:kassi)
    get :show, { :user_id => people(:contact).guid, :format => "json"}
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_equal people(:contact).email, json["entry"]["email"]
    
    # Should not show profile details when role does not exist for this client
    login_as people(:valid_person), clients(:two)
    get :show, { :user_id => people(:contact).guid, :format => "json"}
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_nil(json["entry"]["email"])
    assert_nil(json["entry"]["name"])
    assert_nil(json["entry"]["address"])
    assert_nil(json["entry"]["website"])
    assert_nil(json["entry"]["status"])
    assert_nil(json["entry"]["birthdate"])
    assert_nil(json["entry"]["gender"])
    assert_nil(json["entry"]["avatar"])
    assert_nil(json["entry"]["msn_nick"])
    assert_nil(json["entry"]["phone_number"])
    assert_nil(json["entry"]["msn_nick"])
    assert_nil(json["entry"]["location"])
  end

  private

  def search(search, should_find=true)
    get :index, { :format => 'json', :search => search }, { :cos_session_id => sessions(:session1) }
    assert_response :success, @response.body
    assert_not_nil assigns["people"]

    json = JSON.parse(@response.body)

    if not should_find
      assert_equal 0, json["entry"].length, "Found something with '#{search}'"
      return
    end

    assert_not_equal 0, json["entry"].length, "Found nothing with '#{search}'"

    reg = Regexp.new(search.downcase.tr("*", ""))

    json["entry"].each do |person|
      
      # connection should not be missing, unless that user has no role in the requesting client app
      if person["role"]
        assert_not_nil person["connection"], "Missing connection" 

        if (Person.find(sessions(:session1).person_id).contacts.include?(Person.find_by_guid(person["id"])))
          assert_equal("friend", person["connection"]  )
        elsif (Person.find(sessions(:session1).person_id).pending_contacts.include?(Person.find_by_guid(person["id"])))
          assert_equal("pending", person["connection"]  )
        elsif (Person.find(sessions(:session1).person_id).requested_contacts.include?(Person.find_by_guid(person["id"])))
          assert_equal("requested", person["connection"]  )
        elsif (sessions(:session1).person == Person.find_by_guid(person["id"]))
          assert_equal("you", person["connection"]  )
        else
          assert_equal("none", person["connection"]  )
        end
      end
    end
  end
end
