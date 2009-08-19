class Rule < ActiveRecord::Base
  usesguid # for automatically generating id of rule table

  has_many :condition_action_sets, :dependent => :destroy
  belongs_to :owner, :foreign_key => "person_id", :class_name => "Person"

  accepts_nested_attributes_for :condition_action_sets, :allow_destroy => true
  validates_presence_of :owner
  validates_presence_of [:rule_name, :state, :logic]

  VALID_RULE_STATES = %w(active inactive) # an array
  VALID_RULE_LOGICS = %w(or and)
  NAME_MIN_LENGTH = 2
  NAME_MAX_LENGTH = 70

  validates_length_of :rule_name, :within => NAME_MIN_LENGTH..NAME_MAX_LENGTH
  validates_uniqueness_of :rule_name, :scope => [:person_id]
  validates_inclusion_of :state,
    :in => VALID_RULE_STATES,
    :allow_nil => false,
    :message => "must be 'active' or 'inactive'"

  validates_inclusion_of :logic,
    :in => VALID_RULE_LOGICS,
    :allow_nil => false,
    :message => "must be 'or' or 'and'"
  
  alias_method :orig_update_attributes, :update_attributes

  def update_attributes(attributes)
    orig_update_attributes attributes
  end

  # check if subject_person has the right do a certain ation to data
  # syntax: authorize?(subject_person, object_person_id, action, data)
  # return: true or false
  def Rule.authorize?(connection_person=nil, object_person_id=nil, action=nil, data=nil)
    print "************ in rule/authorize? ******************* \n"
    if connection_person
      print "connection_person.id: #{connection_person.id} \n"
    end
    print "object_person_id: #{object_person_id} \n"
    print "action: #{action} \n"
    print "data: #{data} \n"

    active_rules = Rule.find(:all, :conditions => {'person_id'=>object_person_id, 'state'=>'active'})
    if active_rules.length != 0
      active_rules.each do |rule|
        if rule.authorize_according_to_one_rule(connection_person, object_person_id, action, data)
          return true
        end
      end
    end

    return false
  end

  def to_hash_by_data
    h = Hash.new
    condition_action_sets.each do |set|
      h[set.action.data] = set
    end
    return h
  end


  def condition_action_sets_concerning(data)
    condition_action_sets.find(:all, :conditions => { :actions => { :data => data } }, :joins => [:action] ).inspect
  end

  # get the rule
  def get_rule_hash(asking_person)
    if asking_person.id == self.person_id
      rule_hash = {'rule'  => {
          'id' => id,
          'person_id' => person_id,
          'rule_name' => rule_name,
          'state' => state,
          'logic' => logic,
          'created_at' => created_at,
          'updated_at' => updated_at
        }
      }
    end

    return rule_hash
  end


  # check if the rule is active
  def active?
    return true if self.state == "active"
  end

  # enable the rule
  def enable_rule
      self.update_attribute(:state, 'active')
  end

  # disable the rule
  def disable_rule
      self.update_attribute(:state, 'inactive')
  end

  def set_owner

  end


  def to_json (asking_person, *a)
    rule_hash = get_rule_hash(asking_person)
    return rule_hash.to_json(*a)
  end

  # get all the condition_action_sets belong to this rule
  # return a hash of sets, empty hash if there is no set belong to this rule
  # return value: hash {action_obj1 => [condition_obj1, condition_obj2,...], action_obj2 => conditions_array, ...}
  def get_condition_action_sets_belong_to_the_rule
    sets = ConditionActionSet.find_all_by_rule_id(self.id)
    sets_hash = {}

    if !(sets.empty?)
      sets.each do |item|
        action = Action.find_by_id(item.action_id)
        condition = Condition.find_by_id(item.condition_id)
        if sets_hash.has_key?(action)
          conditions_array = sets_hash.fetch(action)
          conditions_array = conditions_array.push(condition)
          sets_hash[action] = conditions_array
        else
          conditions_array = []
          conditions_array = conditions_array.push(condition)
          sets_hash.merge!({action => conditions_array})
        end
      end
    end
    
    return sets_hash
  end


  # get all the condition_action_sets belong to this rule and corrsponding to specific action and data
  # return an array of sets, empty array if there is no set
  def get_condition_action_sets_by_rule_action_data(action, data)
    ConditionActionSet.get_by_rule_id_action_data(self.id, action, data)
  end

  # check if subject_person has the right do a certain ation to data based on this rule
  def authorize_according_to_one_rule(connection_person, object_person_id, action, data)
    print "************ in rule/authorize_according_to_one_rule ******************* \n"
    print "rule_id: #{self.id} , rule_name: #{self.rule_name}, person_id: #{self.person_id} \n"
    print " "
    result = false
    condition_action_sets = get_condition_action_sets_belong_to_this_rule(action, data)
    if condition_action_sets.length != 0
      condition_action_sets.each do |condition_action_set|
        condition_id = condition_action_set.condition_id
        condition = Condition.find_by_id(condition_id)
        print "condition.id: #{condition.id}, condition.type: #{condition.condition_type}, condition.value: #{condition.condition_value} \n"
        if self.logic == "and"
          if check_condition(connection_person, object_person_id, condition)
            result = true
          else
            return false
          end
        elsif self.logic == "or"
          if check_condition(connection_person, object_person_id, condition)
            result = true
            return result
          end
        end
      end
    end
  end

  private

  # check if the connection_person satisfies a condition
  def check_condition(connection_person=nil, object_person_id=nil, condition=nil)
    print "************ in rule/check_condition ******************* \n"
    if condition
      condition_type = condition.condition_type
      condition_value = condition.condition_value
    end
    print "condition_type:  #{condition_type} \n"
    print "condition_value:  #{condition_value} \n"

    result = false

    case condition_type
    when "logged_in"
      result = check_condition_logged_in(connection_person, condition_value)
    when "group"
      result =  check_condition_group(connection_person, condition_value)
    when "is_friend"
      result = check_condition_friend(connection_person, object_person_id, condition_value)
    when "publicity"
      result = check_condition_publicity(connection_person, object_person_id, condition_value)
    when "user"
      result = check_condition_user(connection_person, condition_value)
      #more condition types can go here
    end

    print "check condition result: #{result} \n"
    return result
  end



  # check if connection_person is logged in
  # if condition_value is true, return true if connection_person is logged in
  # if condition_value is false, return true if connection_person is NOT logged_in
  def check_condition_logged_in(connection_person=nil, condition_value=nil)
    print "************ in rule/check_condition_logged_in ******************* \n"
    if condition_value == nil
      return false
    end

    if condition_value
      if !connection_person.nil?
        return true
      else
        return false
      end
    else
      if connection_person.nil?
        return true
      else
        return false
      end
    end
  end


  # check if connection_person is a member of a group
  # condition_value is group_id
  # return true if connection_person is a member of the group, else return false
  def check_condition_group(connection_person=nil, condition_value=nil)
    print "************ in rule/check_condition_group ******************* \n"
    if !connection_person.nil? && !condition_value.nil?
      group = Group.find_by_id(condition_value)
      return group.membership(connection_person)
    else
      return false
    end
  end

  # check if connection_person is a friend of object_person
  # return true if yes, else return false
  def check_condition_friend(connection_person=nil, object_person_id=nil, condition_value=nil)
    print "************ in rule/check_condition_friend ******************* \n"
    if !connection_person.nil? && !object_person_id.nil? && condition_value
      friend = Connection.find(:all, :conditions => {'person_id' =>  object_person_id, 'contact_id' => connection_person.id, 'status'=>'accepted'})
      if friend.length != 0
        return true
      end
    end

    return false
  end


  # condition_value can be 'Public' or 'Private'
  # When public: every user can perform the action
  # when private: only the user himslef can perform the action
  def check_condition_publicity(connection_person=nil, object_person_id=nil, condition_value=nil)
    print "************ in rule/check_condition_publicity ******************* \n"
    if !connection_person.nil? && !object_person_id.nil? && !condition_value.nil?
      if condition_value == "public"
        return true
      elsif condition_value == "private"
        return (connection_person.id == object_person_id)
      end
    end
    
    return false
  end

  # only a specific user can perform the action
  # condition_value is the username
  def check_condition_user(connection_person=nil, condition_value=nil)
    print "************ in rule/check_condition_user ******************* \n"
    if !connection_person.nil? && !condition_value.nil?
      user = Person.find(:all, :conditions => {'username' => condition_value, 'id'=> connection_person.id})
      if user.length != 0
        return true
      end
    end

    return false
  end

end
