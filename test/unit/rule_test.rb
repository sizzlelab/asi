require 'test_helper'

class RuleTest < ActiveSupport::TestCase


  PROFILE_FIELDS = %W(id username email name status_message birthdate phone_number gender irc_nick msn_nick avatar address location)

  # test validates_presence_of :owner
  def test_invalid_with_empty_person_id
    rule = Rule.new
    assert !rule.valid?
    # The owner field should have validation errors
    assert rule.errors[:owner].any?
  end

  # test validates_presence_of [:rule_name, :state, :logic]
  def test_invalid_with_empty_rule_name_or_state_or_logic
    owner = people(:valid_person)
    rule = Rule.new(:person_id => owner.id)
    assert !rule.valid?
    # The rule_name field should have validation errors
    assert rule.errors[:rule_name].any?
    # The state field should have validation errors
    assert rule.errors[:state].any?
    # The logic field should have validation errors
    assert rule.errors[:logic].any?
  end

  # test validates_length_of :rule_name, :within => NAME_MIN_LENGTH..NAME_MAX_LENGTH
  def test_length_boundaries
    assert_length :min, rules(:active_or_rule), :rule_name, Rule::NAME_MIN_LENGTH
    assert_length :max, rules(:active_or_rule), :rule_name, Rule::NAME_MAX_LENGTH
  end

  # test validates_uniqueness_of :rule_name, :scope => [:person_id]
  def test_rule_name_uniquess_for_a_person
    owner = people(:valid_person)
    rule_1 = Rule.new(:person_id=>owner.id,
                    :rule_name=>"test",
                    :state=>"active",
                    :logic=>"and")
    assert rule_1.save, "Rule 1 cannot be saved."

    rule_2 = Rule.new(:person_id=>owner.id,
                    :rule_name=>"test",
                    :state=>"active",
                    :logic=>"or")
    assert !rule_2.save, "Allows duplicate rule names for a person."
  end


  # test validates_inclusion_of :state,
  #  :in => VALID_RULE_STATES,
  #  :allow_nil => false,
  #  :message => "must be 'active' or 'inactive'"
  def test_invalid_state
    owner = people(:valid_person)
    rule = Rule.new(:person_id=>owner.id,
                    :rule_name=>"test",
                    :state=>"aaaactive",
                    :logic=>"and")
    assert !rule.valid?
    # The state field should have validation errors
    assert rule.errors[:state].any?
  end

  # test validates_inclusion_of :logic,
  #  :in => VALID_RULE_LOGICS,
  #  :allow_nil => false,
  #  :message => "must be 'or' or 'and'"
  def test_invalid_logic
    owner = people(:valid_person)
    rule = Rule.new(:person_id=>owner.id,
                    :rule_name=>"test",
                    :state=>"active",
                    :logic=>"aaaaaand")
    assert !rule.valid?
    # The logic field should have validation errors
    assert rule.errors[:logic].any?
  end

  # test update_attributes
  #def test_update_attributes

  #end

  #test authorize(subject_person, object_person_id, action_type, action_value)
  #return true if authorized, false if not authorized
  def test_authorize
    object_person = people(:valid_person) # person_id 1
    subject_person_1aa = people(:person1) # person_id 1aa
    subject_person_2aa = people(:person3) # person_id 2aa
    
    assert Rule.authorize?(subject_person_1aa, object_person.id, "view", "email")
    assert !Rule.authorize?(subject_person_2aa, object_person.id, "view","email")

  end


  def test_authorize_action_on_multiple_data
    object_person_3 = people(:contact) # person_id 3, with a default profile rule setting username as 'public' and other profile fields 'private'
    object_person_1 = people(:valid_person) # person_id 1, without default profile rule, but person 1aa can view its name and email
    subject_person = people(:person1) # person_id 1aa
    action_value_array = PROFILE_FIELDS
    
    accessible_array = Rule.authorize_action_on_multiple_data(subject_person, object_person_3.id, "view", action_value_array)
    assert_not_nil accessible_array, "Accissable action values array should not be nil."
    assert_equal accessible_array.length, 1, "There should be one and only one field (username) accessible."
    assert_equal accessible_array[0], "username", "Username should be the only field accessible."
  end

  # test get_rule_hash(asking_person)
  #def test_get_rule_hash

  #end

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
  # return hash {action_obj => conditons_array}
  def test_get_condition_action_sets_belong_to_the_rule
    rule_1 = rules(:active_or_rule) # friends or members of group tkk can view name of person 1, with 2 condition_action_sets
    rule_2 = rules(:profile_rule_for_3) # default profile rule for person 3, with 13 condition_action_sets
    rule_3 = rules(:test_rule) # with no condition_action_sets
    c_a_sets_1 = rule_1.get_condition_action_sets_belong_to_the_rule
    c_a_sets_2 = rule_2.get_condition_action_sets_belong_to_the_rule
    c_a_sets_3 = rule_3.get_condition_action_sets_belong_to_the_rule
    assert_not_nil c_a_sets_1
    assert_equal c_a_sets_1.size, 1, "There should be 2 condition_action_set (one hash entry) for rule_1"
    assert_not_nil c_a_sets_2
    assert_equal c_a_sets_2.length, 13, "There should be 13 condition_action_sets (13 hash entries) for rule_2"
    assert_not_nil c_a_sets_3
    assert_equal c_a_sets_3.length, 0, "There should be 0 condition_action_sets (0 hash entry) for rule_3"
  end

  # test  get_condition_action_sets_by_rule_action_data(action_type, action_value)
  def test_get_condition_action_sets_by_rule_action_data
    rule_1 = rules(:active_or_rule) # friends or members of group tkk can view name of person 1
    rule_2 = rules(:profile_rule_for_3) # default profile rule for person 3
    c_a_sets_1 = rule_1.get_condition_action_sets_by_rule_action_type_value("view", "name")
    c_a_sets_2 = rule_2.get_condition_action_sets_by_rule_action_type_value("view", "name")
    assert_not_nil c_a_sets_1
    assert_equal c_a_sets_1.length, 2, "There should be 2 condition_action_sets for rule_1 view name"
    assert_not_nil c_a_sets_1[0]
    assert_not_nil c_a_sets_1[1]
    assert_not_nil c_a_sets_2
    assert_equal c_a_sets_2.length, 1, "There should be 1 condition_action_set for rule_2 view name"
    assert_not_nil c_a_sets_2[0]
    assert_equal c_a_sets_2[0], condition_action_sets(:rule3_name),"condition_action_set for rule2 should be private-> view name"
  end

#  test authorize_according_to_one_rule(subject_person, object_person_id, action_type, action_value)
  def test_authorize_according_to_one_rule
    rule_or = rules(:active_or_rule) # friends or members of group tkk can view name of person 1
    rule_and = rules(:active_and_rule) # friends who are members of group tkk can view email of person 1

    action_view_name = actions(:view_name)
    action_view_email = actions(:view_email)
    object_person = people(:valid_person) # person id 1
    subject_person_test = people(:test) # not friend, not member of group tkk
    subject_person_4 = people(:friend) # person 4 is a friend, but not a member of group tkk
    subject_person_1aa = people(:person1) # person 1aa is a friend, and also a member of group tkk

    assert subject_person_1aa.contacts.include? object_person
    assert subject_person_1aa.is_member_of? groups(:tkk)

    assert !rule_or.authorize_according_to_one_rule(subject_person_test, object_person.id, action_view_name.action_type, action_view_name.action_value)
    assert !rule_and.authorize_according_to_one_rule(subject_person_test, object_person.id, action_view_email.action_type, action_view_email.action_value)
    assert rule_or.authorize_according_to_one_rule(subject_person_4, object_person.id, action_view_name.action_type, action_view_name.action_value)
    assert !rule_and.authorize_according_to_one_rule(subject_person_4, object_person.id, action_view_email.action_type, action_view_email.action_value)
    assert rule_or.authorize_according_to_one_rule(subject_person_1aa, object_person.id, action_view_name.action_type, action_view_name.action_value)
    assert rule_and.authorize_according_to_one_rule(subject_person_1aa, object_person.id, action_view_email.action_type, action_view_email.action_value)
  end


  # test private methods

  # test check_condition(subject_person=nil, object_person_id=nil, condition=nil)
  # def test_check_condition
  #   subject_person_test = people(:test)
  #   subject_person_1aa = people(:person1) # 1aa is member of group tkk, friend of 1, satisfy condition_user
  #   object_person = people(:valid_person) # person id 1
  #   condition_private = conditions(:private)
  #   condition_public = conditions(:public)
  #   condition_logged_in = conditions(:logged_in)
  #   condition_is_friend = conditions(:is_friend)
  #   condition_group = conditions(:group)
  #   condition_user = conditions(:user)
  #   rule = rules(:test_rule)
  #   # expose private methods of the test object rule
  #   class << rule
  #     public :check_condition
  #   end

  #   assert !rule.check_condition(subject_person_test, object_person.id, condition_private)
  #   assert rule.check_condition(subject_person_test, object_person.id, condition_public)
  #   assert rule.check_condition(subject_person_test, object_person.id, condition_logged_in)
  #   assert !rule.check_condition(subject_person_test, object_person.id, condition_is_friend)
  #   assert rule.check_condition(subject_person_1aa, object_person.id, condition_is_friend)
  #   assert !rule.check_condition(subject_person_test, object_person.id, condition_group)
  #   assert rule.check_condition(subject_person_1aa, object_person.id, condition_group)
  #   assert !rule.check_condition(subject_person_test, object_person.id, condition_user)
  #   assert rule.check_condition(subject_person_1aa, object_person.id, condition_user)
  # end

  # test check_condition_logged_in(subject_person, condition_value)
  def test_check_condition_logged_in
    rule = rules(:test_rule)
    # expose private methods of the test object rule
    class << rule
      public :check_condition_logged_in
    end

    subject_person1 = nil
    subject_person2 = people(:valid_person)
    assert !rule.check_condition_logged_in(subject_person1, true)
    assert rule.check_condition_logged_in(subject_person2, true)
    assert rule.check_condition_logged_in(subject_person1, false)
    assert !rule.check_condition_logged_in(subject_person2, false)
  end

  # test check_condition_group
  def test_check_condition_group
    rule = rules(:test_rule)
    # expose private methods of the test object rule
    class << rule
      public :check_condition_group
    end

    subject_person1 = people(:valid_person)
    subject_person2 = people(:test)
    group = groups(:open)
    assert rule.check_condition_group(subject_person1, group.id), "Group condition check failed"
    assert !rule.check_condition_group(subject_person2, group.id), "Group condition check failed"
  end

  # test check_condition_friend
  def test_check_condition_friend
    rule = rules(:test_rule)
    # expose private methods of the test object rule
    class << rule
      public :check_condition_friend
    end

    object_person = people(:valid_person)
    subject_person_friend = people(:friend)
    subject_person_pending = people(:requested)
    subject_person_not_friend = people(:test)
    assert rule.check_condition_friend(subject_person_friend, object_person.id, true), "Friend condition check failed"
    assert !rule.check_condition_friend(subject_person_pending, object_person.id, true), "Friend condition check failed"
    assert !rule.check_condition_friend(subject_person_not_friend, object_person.id, true), "Friend condition check failed"
  end

  # test check_condition_publicity
  def test_check_condition_publicity
    rule = rules(:test_rule)
    # expose private methods of the test object rule
    class << rule
      public :check_condition_publicity
    end

    object_person = people(:valid_person)
    subject_person = people(:test)
    assert rule.check_condition_publicity(subject_person, object_person.id, "public"), "Publicity condition check failed"
    assert rule.check_condition_publicity(object_person, object_person.id, "private"), "Publicity condition check failed"
    assert !rule.check_condition_publicity(subject_person, object_person.id, "private"), "Publicity condition check failed"
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
