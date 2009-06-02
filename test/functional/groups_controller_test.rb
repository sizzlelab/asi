require 'test_helper'
require 'json'

class GroupsControllerTest < ActionController::TestCase
  fixtures :people

  def test_create
    description_text = "A group that is used for testing. It is veery nice that you can
                        write even a little longer story here to describe the purpose and the
                        ideology of the group... Ja even ääkköset should work here. :)"
    post :create, {:title => "testgroup", :type => "open", 
         :description => description_text,
         :format => 'json'}, { :cos_session_id => sessions(:session1).id }
    assert_response :created, @response.body
    json = JSON.parse(@response.body)
    #puts json.inspect
    assert id = json["group"]["id"]
    assert(Group.find_by_title("testgroup"), "Created group not found.")
    assert(Group.find_by_title("testgroup").members.first.is_admin_of?(Group.find_by_id(id)), 
            "Creator was not made admin in new group")
    group = Group.find(id)
    assert_equal(description_text, group.description)
    assert_equal(sessions(:session1).person.id, group.created_by)  
  end
  
  def test_show
    get :show, {:group_id =>  groups(:open).id, :format => 'json'}, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_equal(groups(:open).title, json['group']['title'])
    assert_equal(groups(:open).description, json['group']['description'])
    assert_equal(groups(:open).id, json['group']['id'])
    assert_equal(groups(:open).members.count, json['group']['number_of_members'])
    assert_equal(groups(:open).created_by, json['group']['created_by'])
    assert_equal(groups(:open).group_type, json['group']['group_type'])
    #assert_equal(groups(:open).created_at, json['group']['created_at']) #format problems prevent easy testing
    assert_equal(groups(:open).has_member?(sessions(:session1).person), json['group']['is_member'])
  end
  
  def test_add_member
    assert ! groups(:open).has_member?(people(:friend))
    post :add_member, {:group_id =>  groups(:open).id, :user_id => people(:friend).id, :format => 'json' },
                      { :cos_session_id => sessions(:session4).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert groups(:open).has_member?(people(:friend))
    assert people(:friend).is_member_of?(groups(:open))
    
    # Should not be able to add a friend to a group (session is associated to different person)
    post :add_member, {:group_id =>  groups(:open).id, :user_id => people(:friend).id, :format => 'json' },
                      { :cos_session_id => sessions(:session1).id }
    assert_response :forbidden, @response.body
    json = JSON.parse(@response.body)                  
    
  end
  
  def test_get_groups_of_person
    get :get_groups_of_person, {:user_id => people(:valid_person).id, :format => 'json' }, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert(json["entry"], "Malformed json response.")
    # check that number of groups match
    assert_equal(people(:valid_person).groups.size,json["entry"].size)
  end
  
  def test_get_public_groups
    get :public_groups, { :format => 'json' }, { :cos_session_id => sessions(:client_only_session).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert json["entry"]
    assert_equal(3, json["entry"].size)
  end
  
  def test_get_members_of_group
    get :get_members, {:group_id =>  groups(:open).id, :format => 'json' },
                      { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert json["entry"]
    assert_equal(2, json["entry"].size)
    assert( json["entry"].first["id"] == people(:valid_person).id || json["entry"].first["id"] == people(:contact).id ) 
    
    # try to get members of unexisting group
    get :get_members, {:group_id =>  "non_existent_id", :format => 'json' },
                      { :cos_session_id => sessions(:session1).id }
    assert_response :not_found, @response.body
          
  end
  
  def test_removing_a_member
    assert groups(:open).has_member?(people(:valid_person))
    delete :remove_person_from_group, {:group_id =>  groups(:open).id, :user_id => people(:valid_person).id, :format => 'json' },
                      { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert ! groups(:open).has_member?(people(:valid_person)), "Removing a group member failed!"
    assert ! people(:valid_person).is_member_of?(groups(:open))
    
    # Should not be able to remove an other person from a group (session is associated to different person)
    delete :remove_person_from_group, {:group_id =>  groups(:open).id, :user_id => people(:valid_person).id, :format => 'json' },
                      { :cos_session_id => sessions(:session4).id }
    assert_response :forbidden, @response.body
    json = JSON.parse(@response.body)
    
    # Should destroy the group when the last person leaves
    assert groups(:open).has_member?(people(:contact))
    assert_not_nil(Group.find_by_id(groups(:open).id))
    delete :remove_person_from_group, {:group_id =>  groups(:open).id, :user_id => people(:contact).id, :format => 'json' },
                      { :cos_session_id => sessions(:session7).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    #assert ! groups(:open).has_member?(people(:valid_person)), "Removing a group member failed!"
    #assert ! people(:valid_person).is_member_of?(groups(:open))
    assert_nil(Group.find_by_id(groups(:open).id),"Group not destroyed when last person leaved.")
  end
end
