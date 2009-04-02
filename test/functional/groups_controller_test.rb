require 'test_helper'
require 'json'

class GroupsControllerTest < ActionController::TestCase
  fixtures :people

  def test_create
    post :create, {:title => "testgroup", :type => "open", :format => 'json'}, { :session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    #puts json.inspect
    assert id = json["group"]["id"]
    assert(Group.find_by_title("testgroup"), "Created group not found.")
    assert(Group.find_by_title("testgroup").members.first.is_admin_of?(Group.find_by_id(id)), 
            "Creator was not made admin in new group")
      
  end
  
  def test_show
    get :show, {:group_id =>  groups(:open).id, :format => 'json'}, { :session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_equal(groups(:open).title, json['group']['title'])
  end
  
  def test_add_member
    assert ! groups(:open).has_member?(people(:friend))
    post :add_member, {:group_id =>  groups(:open).id, :user_id => people(:friend).id, :format => 'json' },
                      { :session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert groups(:open).has_member?(people(:friend))
    assert people(:friend).is_member_of?(groups(:open))
  end
  
  def test_get_groups_of_person
    get :get_groups_of_person, {:user_id => people(:valid_person).id, :format => 'json' }, { :session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert(json["entry"], "Malformed json response.")
    # check that number of groups match
    assert_equal(people(:valid_person).groups.size,json["entry"].size)
  end
  
  def test_get_public_groups
    get :public_groups, { :format => 'json' }, { :session_id => sessions(:client_only_session).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert json["entry"]
    assert_equal(3, json["entry"].size)
  end
  
  def test_get_members_of_group
    get :get_members, {:group_id =>  groups(:open).id, :format => 'json' },
                      { :session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert json["entry"]
    assert_equal(2, json["entry"].size)
    assert( json["entry"].first["id"] == people(:valid_person).id || json["entry"].first["id"] == people(:contact).id )           
  end
end
