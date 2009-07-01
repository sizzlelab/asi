# -*- coding: utf-8 -*-
require 'test_helper'
require 'json'

class GroupsControllerTest < ActionController::TestCase
  fixtures :people

  def test_create
    [ "open", "closed" ].each do |type|
      description_text = "A group that is used for testing. It is veery nice that you can
                        write even a little longer story here to describe the purpose and the
                        ideology of the group... Ja even ääkköset should work here. :)"
      title = "testgroup (#{type})"
      post :create, {:title => title, :type => type, 
        :description => description_text,
        :format => 'json'}, { :cos_session_id => sessions(:session1).id }
      assert_response :created, @response.body
      json = JSON.parse(@response.body)
      #puts json.inspect
      assert id = json["group"]["id"]
      group = Group.find(id)
      assert(group, "Created group not found. (#{type})")
      assert(group.members.include?(sessions(:session1).person), "Creator was not made member of new group (#{type})")
      assert(group.members.first.is_admin_of?(Group.find_by_id(id)), 
             "Creator was not made admin in new group (#{type})")
      assert_equal(description_text, group.description)
      assert_equal(sessions(:session1).person.id, group.created_by)  
    end
  end

  def test_grant_and_remove_admin_status
    person = people(:friend)
    admin = groups(:open).members.first;
    session = sessions(:session1)

    assert admin.is_admin_of?(groups(:open))
    assert ! person.is_admin_of?(groups(:open))

    assert admin.id == session.person_id
    assert person != admin

    assert ! groups(:open).has_member?(person)
    post :add_member, {:group_id =>  groups(:open).id, :user_id => person.id, :format => 'json' },
                      { :cos_session_id => sessions(:session4).id }
    assert_response :success, @response.body

    put :update_membership_status, {:group_id => groups(:open).id, :admin_status => true, :user_id => person.id, :format => 'json'},
                                   {:cos_session_id => session.id}
    assert_response :success

    assert person.is_admin_of?(groups(:open)), "Granting admin rights failed."

    put :update_membership_status, {:group_id => groups(:open).id, :admin_status => false, :user_id => person.id, :format => 'json'},
                                   {:cos_session_id => sessions(:session4).id}
    assert_response :forbidden
    assert person.is_admin_of?(groups(:open)), "Person should still be admin. Removing admin rights from self is forbidden."

    put :update_membership_status, {:group_id => groups(:open).id, :admin_status => false, :user_id => person.id, :format => 'json'},
                                   {:cos_session_id => session.id}
    assert_response :success
    assert ! person.is_admin_of?(groups(:open)), "Removing of admin rights didn't work."

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

  def test_not_found
    get :show, { :group_id => "nonexistent", :format => 'json'}, { :cos_session_id => sessions(:session1).id }
    assert_response :not_found, @response.body
  end

   def test_request_and_accept_membership
    group = groups(:closed)
    session = sessions(:session1)
    assert session.person.is_admin_of?(group)
    
    assert ! groups(:closed).has_member?(people(:friend))

    post :add_member, {:group_id =>  groups(:closed), :user_id => people(:friend).id, :format => 'json' },
                      { :cos_session_id => sessions(:session4).id }
                    
    assert_response :accepted

    assert groups(:closed).pending_members.include?(people(:friend))

    put :update_membership_status, {:group_id =>  groups(:closed), :user_id => people(:friend).id, :accepted => true, :format => 'json' },
                                   { :cos_session_id => sessions(:session1).id }
    assert_response :ok
    assert groups(:closed).has_member?(people(:friend))
  end

   def test_unauthorized_membership_accept
     assert ! groups(:closed).has_member?(people(:friend))

     post :add_member, {:group_id =>  groups(:closed), :user_id => people(:friend).id, :format => 'json' },
                      { :cos_session_id => sessions(:session4).id }

     put :update_membership_status, {:group_id => groups(:closed), :user_id => people(:friend).id, :accepted => true, :format => 'json'},
                                             {:cos_session_id => sessions(:session4).id }
     assert_response :forbidden
     
     assert ! groups(:closed).has_member?(people(:friend))
   end

  
  def test_add_member
    assert ! groups(:open).has_member?(people(:friend))
    post :add_member, {:group_id =>  groups(:open).id, :user_id => people(:friend).id, :format => 'json' },
                      { :cos_session_id => sessions(:session4).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert groups(:open).has_member?(people(:friend))
    assert people(:friend).is_member_of?(groups(:open))
  end

  def test_rejoin
    assert ! groups(:open).has_member?(people(:friend))
    post :add_member, {:group_id =>  groups(:open).id, :user_id => people(:friend).id, :format => 'json' },
                      { :cos_session_id => sessions(:session4).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert groups(:open).has_member?(people(:friend))
    assert people(:friend).is_member_of?(groups(:open))

    post :add_member, {:group_id =>  groups(:open).id, :user_id => people(:friend).id, :format => 'json' },
                      { :cos_session_id => sessions(:session4).id }
    assert_response :conflict, @response.body
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
    assert_equal(4, json["entry"].size)
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

  def test_change_group_info
    group = groups(:open)
    session = sessions(:session1)
    assert session.person.is_admin_of?(group)

    data =  { :description => "foo Ja even ääkköset ",
              :title => "baaaa Ja even ääkköset äääää" }

    put :update, { :group_id => group.id, :group => data, :format => 'json' },
                 { :cos_session_id => session.id }
    assert_response :ok, @response.body

    json = JSON.parse(@response.body)

    data.each do |key, value|
      assert_equal(data[key], json["group"][key.to_s])
    end
  end

  def test_try_change_group_info_to_invalid
    group = groups(:open)
    session = sessions(:session1)
    assert session.person.is_admin_of?(group)

    data =  { :title => "a" }

    put :update, { :group_id => group.id, :group => data, :format => 'json' },
                 { :cos_session_id => session.id }
    assert_response :bad_request, @response.body

    json = JSON.parse(@response.body)

    get :show, { :group_id => group.id, :format => 'json' },
               { :cos_session_id => session.id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)

    data.each do |key, value|
      assert_not_equal(data[key], json["group"][key.to_s])
    end    
  end

  def test_try_change_group_info_illegally
    group = groups(:open)
    session = sessions(:session1)
    assert session.person.is_admin_of?(group)

    data =  { :created_by => "foo",
              :updated_at => "01-01-1950 10:10:10" }

    put :update, { :group_id => group.id, :group => data, :format => 'json' },
                 { :cos_session_id => session.id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)

    get :show, { :group_id => group.id, :format => 'json' },
               { :cos_session_id => session.id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)

    data.each do |key, value|
      assert_not_equal(data[key], json["group"][key.to_s])
    end    
  end


  def test_try_change_group_info_unauthorized
    group = groups(:open)
    session = sessions(:session2)
    assert ! session.person.is_admin_of?(group)

    data =  { :title => "Foobar" }

    put :update, { :group_id => group.id, :group => data, :format => 'json' },
                 { :cos_session_id => session.id }
    assert_response :forbidden, @response.body
    json = JSON.parse(@response.body)    

    get :show, { :group_id => group.id, :format => 'json' },
               { :cos_session_id => session.id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)

    data.each do |key, value|
      assert_not_equal(data[key], json["group"][key.to_s])
    end    
  end

  def test_kick
    group = groups(:open)
    session = sessions(:session1)
    assert session.person.is_admin_of?(group)
    user = group.members[1]
    assert_not_equal user, session.person

    delete :remove_person_from_group, {:group_id => group.id, :user_id => user.id, :format => 'json' },
    { :cos_session_id => session.id }
    assert_response :success, @response.body

    get :get_members, {:group_id => group.id, :user_id => user.id, :format => 'json'},
    { :cos_session_id => session.id }
    assert_response :success, @response.body

    json = JSON.parse(@response.body)
    
    assert json["entry"].size < group.members.size
  end

  def test_unauthorized_kick
    group = groups(:open)
    session = sessions(:session5)
    assert ! session.person.is_admin_of?(group)
    user = group.members[1]
    assert_not_equal user, session.person

    delete :remove_person_from_group, {:group_id => group.id, :user_id => user.id, :format => 'json' },
    { :cos_session_id => session.id }
    assert_response :forbidden, @response.body

    get :get_members, {:group_id => group.id, :user_id => user.id, :format => 'json'},
    { :cos_session_id => session.id }
    assert_response :success, @response.body

    json = JSON.parse(@response.body)
    
    assert_equal json["entry"].size, group.members.size
  end

  def test_duplicate_group
    group = groups(:open)
    session = sessions(:session1)
    
    post :create, { :title => group.title, :type => "open", :format => 'json' }, 
                  { :cos_session_id => session.id }
    assert_response :bad_request, @response.body
    json = JSON.parse(@response.body)
  end
  
  def test_not_found
    assert ! groups(:open).has_member?(people(:friend))
    post :add_member, {:group_id =>  "foo", :user_id => people(:friend).id, :format => 'json' },
                      { :cos_session_id => sessions(:session4).id }
    assert_response :not_found, @response.body
    json = JSON.parse(@response.body)
  end

  def test_get_pending_membership_requests
    group = groups(:closed)
    session = sessions(:session1)
    assert session.person.is_admin_of?(group)

    get :get_pending_members, { :group_id => group.id, :format => 'json' },
    { :cos_session_id => session.id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
  end

  def test_send_invite
    group = groups(:closed)
    session = sessions(:session1)
    assert session.person.is_admin_of?(group)

    post :add_member, { :user_id => people(:friend).id, :group_id => group.id, :format => 'json' }, 
                      { :cos_session_id => session.id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
  end

  def test_send_unauthorized_invite
    group = groups(:hidden)
    session = sessions(:session8)
    assert session.person.is_member_of?(group)
    assert ! session.person.is_admin_of?(group)

    post :add_member, { :user_id => people(:friend).id, :group_id => group.id, :format => 'json' }, 
                      { :cos_session_id => session.id }
    assert_response :forbidden, @response.body
    json = JSON.parse(@response.body)  
  end

  def test_change_group_type_to_open
    data = {:group_type => 'open'}

    group = groups(:hidden)
    admin = group.creator

    put :update, {:group => data, :group_id => group.id, :format => 'json' },
                 {:cos_session_id => sessions(:session1).id}
    assert_response :ok, @response.body
    group.reload
    assert group.group_type == "open", 'Group type should be open"'


    group = groups(:closed)
    admin = group.creator

    post :add_member, {:group_id =>  group, :user_id => people(:friend).id, :format => 'json' },
                      { :cos_session_id => sessions(:session4).id }

    assert ! group.pending_members.empty?, "Should be one pending member in the group."
    assert ! people(:friend).is_member_of?(group), "Person shouldn't be member."

    put :update, {:group => data, :group_id => group.id, :format => 'json' },
                 {:cos_session_id => sessions(:session1).id}

    assert_response :ok, @response.body
    group.reload
    assert group.group_type == "open", 'Group type should be open"'

    assert people(:friend).is_member_of?(group), "Person should have been accepted as a member"

  end

  def test_change_group_type_to_closed

    data = {:group_type => 'closed'}

    [groups(:open), groups(:hidden)].each do |group|
      put :update, { :group => data, :group_id => group.id, :format => 'json'},
                    { :cos_session_id => sessions(:session1).id}
      assert_response :ok, @response.body
      group.reload
      assert group.group_type == "closed", "Group type should have been changed to closed."
    end
  end

  def test_change_group_type_to_hidden
    data = {:group_type => 'hidden'}
    [groups(:open), groups(:closed)].each do |group|
      put :update, { :group => data, :group_id => group.id, :format => 'json'},
                    { :cos_session_id => sessions(:session1).id}
      assert_response :ok, @response.body
      group.reload
      assert group.group_type == "hidden", "Group type should have been changed to hidden."
    end
  end

end
