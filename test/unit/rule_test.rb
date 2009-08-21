require 'test_helper'

class RuleTest < ActiveSupport::TestCase

  #test "the truth" do
  #  assert true
  #end

  

  

  # test update_attributes
  def test_update_attributes
    
  end

  # test authorize
  def test_authorize?

  end

  # test authorize_actions
  def test_authorize_actions
    
  end

  # test get_rule_hash
  def test_get_rule_hash
    
  end



  # test active
  def test_active?
    active_rule = rules(:active_or_rule)
    assert active_rule.active?, "The rule should be active"
    inactive_rule = rules(:inactive_rule)
    assert !inactive_rule.active?, "The rule should be inactive"
  end

  # test enable_rule
  def test_enable_rule
    inactive_rule = rules(:inactive_rule)
    inactive_rule.enable_rule
    assert inactive_rule.active?, "The rule should be enabled"
  end


  # test disable_rule
  def test_disable_rule
    active_rule = rules(:active_and_rule)
    active_rule.disable_rule
    assert !active_rule.active?, "The rule should be disabled"
  end

  # test get_condition_action_sets_belong_to_the_rule
  def test_get_condition_action_sets_belong_to_the_rule
    
  end

  # test  get_condition_action_sets_by_rule_action_data(action, data)
  def test_get_condition_action_sets_by_rule_action_data
    
  end

  # test authorize_according_to_one_rule(connection_person, object_person_id, action, data)
  def test_authorize_according_to_one_rule
    rule_or = rules(:active_or_rule) # friends or members of group tkk can view name of person 1
    rule_and = rules(:active_and_rule) # friends who are members of group tkk can view email of person 1
    action_view_name = actions(:view_name)
    action_view_email = actions(:view_email)
    connection_person = people(1)
    object_person = people(:valid_person) # person id 1
    connection_person_test = people(:test) # not friend, not member of group tkk
    connection_person_friend_group_mem = people(:friend) # person 4 is a friend, and also a member of group tkk
    connection_person_friend_not_group_mem = people(:contact) # person 3 is a friend, but not a member of group tkk

    assert rule_or.authorize_according_to_one_rule(connection_person_test, object_person.id, action, data)
  end


  # test private methods

  # test check_condition(connection_person=nil, object_person_id=nil, condition=nil)
  def test_check_condition
    connection_person_test = people(:test)
    connection_person_1aa = people(:person1) # 1aa is member of group tkk, friend of 1, satisfy condition_user
    object_person = people(:valid_person) # person id 1
    condition_private = conditions(:private)
    condition_public = conditions(:public)
    condition_logged_in = conditions(:logged_in)
    condition_is_friend = conditions(:is_friend)
    condition_group = conditions(:group)
    condition_user = conditions(:user)
    rule = rules(:test_rule)
    # expose private methods of the test object rule
    class << rule
      public :check_condition
    end

    assert !rule.check_condition(connection_person_test, object_person.id, condition_private)
    assert rule.check_condition(connection_person_test, object_person.id, condition_public)
    assert rule.check_condition(connection_person_test, object_person.id, condition_logged_in)
    assert !rule.check_condition(connection_person_test, object_person.id, condition_is_friend)
    assert rule.check_condition(connection_person_1aa, object_person.id, condition_is_friend)
    assert !rule.check_condition(connection_person_test, object_person.id, condition_group)
    #assert rule.check_condition(connection_person_1aa, object_person.id, condition_group)
    assert !rule.check_condition(connection_person_test, object_person.id, condition_user)
    #assert rule.check_condition(connection_person_1aa, object_person.id, condition_user)
  end

  # test check_condition_logged_in(connection_person, condition_value)
  def test_check_condition_logged_in
    rule = rules(:test_rule)
    # expose private methods of the test object rule
    class << rule
      public :check_condition_logged_in
    end

    connection_person1 = nil
    connection_person2 = people(:valid_person)
    assert !rule.check_condition_logged_in(connection_person1, true)
    assert rule.check_condition_logged_in(connection_person2, true)
    assert rule.check_condition_logged_in(connection_person1, false)
    assert !rule.check_condition_logged_in(connection_person2, false)
  end

  # test check_condition_group
  def test_check_condition_group
    rule = rules(:test_rule)
    # expose private methods of the test object rule
    class << rule
      public :check_condition_group
    end

    connection_person1 = people(:valid_person)
    connection_person2 = people(:test)
    group = groups(:open)
    assert rule.check_condition_group(connection_person1, group.id), "Group condition check failed"
    assert !rule.check_condition_group(connection_person2, group.id), "Group condition check failed"
  end

  # test check_condition_friend
  def test_check_condition_friend
    rule = rules(:test_rule)
    # expose private methods of the test object rule
    class << rule
      public :check_condition_friend
    end

    object_person = people(:valid_person)
    connection_person_friend = people(:friend)
    connection_person_pending = people(:requested)
    connection_person_not_friend = people(:test)
    assert rule.check_condition_friend(connection_person_friend, object_person.id, true), "Friend condition check failed"
    assert !rule.check_condition_friend(connection_person_pending, object_person.id, true), "Friend condition check failed"
    assert !rule.check_condition_friend(connection_person_not_friend, object_person.id, true), "Friend condition check failed"
  end

  # test check_condition_publicity
  def test_check_condition_publicity
    rule = rules(:test_rule)
    # expose private methods of the test object rule
    class << rule
      public :check_condition_publicity
    end

    object_person = people(:valid_person)
    connection_person = people(:test)
    assert rule.check_condition_publicity(connection_person, object_person.id, "public"), "Publicity condition check failed"
    assert rule.check_condition_publicity(object_person, object_person.id, "private"), "Publicity condition check failed"
    assert !rule.check_condition_publicity(connection_person, object_person.id, "private"), "Publicity condition check failed"
  end

  # test check_condition_user
  def test_check_condition_user
    rule = rules(:test_rule)
    # expose private methods of the test object rule
    class << rule
      public :check_condition_user
    end

    person = people(:valid_person)
    assert rule.check_condition_user(person, "kusti"), "User condition check failed"
    assert !rule.check_condition_user(person, "contact"), "User condition check failed"
  end

end
