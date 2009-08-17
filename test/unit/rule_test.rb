require 'test_helper'

class RuleTest < ActiveSupport::TestCase

  #test "the truth" do
  #  assert true
  #end

  

  
 # test rule create
  def test_create_rule
    
  end

  # test update_attributes
  def test_update_attributes
    
  end

  # test authorize
  def test_authorize?

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

  # test authorize_according_to_one_rule
  def test_authorize_according_to_one_rule
    
  end


  # test private methods

  # test check_condition_logged_in
  def test_check_condition_logged_in
    rule = rules(:test_rule)
    # expose private methods of the test object rule
    class << rule
      public :check_condition_logged_in
    end

    
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
