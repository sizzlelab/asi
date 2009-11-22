class Rule < ActiveRecord::Base
  usesguid # for automatically generating id of rule table

  has_many :condition_action_sets, :dependent => :destroy
  belongs_to :owner, :foreign_key => "person_id", :class_name => "Person"

  validates_presence_of :owner
  validates_presence_of [:rule_name, :state, :logic]

  VALID_RULE_STATES = %w(active inactive) # an array
  VALID_RULE_LOGICS = %w(or and)
  NAME_MIN_LENGTH = 2
  NAME_MAX_LENGTH = 70

  #added by marcos to make the default creation
  PROFILE_FIELDS = %W(id username email name status_message birthdate phone_number gender irc_nick msn_nick avatar address location)

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

  # check if subject_person has the right do a certain ation (action_type) to data (action_value)
  # syntax: authorize?(subject_person, object_person_id, action_type, action_value)
  # return: true or false
  def Rule.authorize?(subject_person=nil, object_person_id=nil, action_type=nil, action_value=nil)
    # print "************ in rule/authorize? ******************* \n"
    # if subject_person
    #  print "subject_person.id: #{subject_person.id} \n"
    # end
    #print "object_person_id: #{object_person_id} \n"
    #print "action_type: #{action_type} \n"
    #print "action_value: #{action_value} \n"

    active_rules = Rule.find(:all, :conditions => {'person_id'=>object_person_id, 'state'=>'active'})

    if active_rules.length != 0
      active_rules.each do |rule|
        if rule.authorize_according_to_one_rule(subject_person, object_person_id, action_type, action_value)
          return true
        end
      end
      return false
    end

    return true
  end

  # check if subject_person has the right to do an action ("view", "comment"...)
  # to an array of data (action_value_array)
  # params: subject_person, object_person_id, action_type, action_value_array
  # return: array that contains data which are accessible to subject_person
  # usage example: pass all the profile fields as action_value_array, and return
  # profile fields that can be viewed by subject_person
  def Rule.authorize_action_on_multiple_data(subject_person=nil, object_person_id=nil, action_type=nil, action_value_array=nil)
    result_array = []
    if action_value_array
      action_value_array.each do |action_value|
        if Rule.authorize?(subject_person, object_person_id, action_type, action_value)
          result_array = result_array.push(action_value)
        end
      end
    end
    return result_array
  end

  # when a new user is created, a default profile rule with rule name "profile
  # privacy"is automatically created for him.
  # The user can edit the profile rule later
  # default profile rule sets profile fieds username 'public', and all
  # the other fields "private"
  def Rule.create_default_profile_rule(person)


#    parameters_hash = HashWithIndifferentAccess.new(params.clone)
#    params = fix_utf8_characters(parameters_hash) #fix nordic letters in person details

    @rule = Rule.new(:person_id => person.id,
                    :rule_name => "profile privacy",
                    :state => "active",
                    :logic => "and")

    # sets rule id as "person_id rule_name"
    # rule id cannot be set by "new", because id is protected attributes
    #@rule.id = params[:user_id] + " profile rule"
    # rule id is now generated automatically using 'usesguid' plugin

    # create condition_action_sets for this profile rule
    sets_hash = {}
    PROFILE_FIELDS.each do |field|
      if field == "username"
        sets_hash.merge!({field => "public"})
      else
        sets_hash.merge!({field => "private"})
      end
    end

    condition_public = Condition.find_by_condition_type_and_condition_value("publicity", "public")
    condition_private = Condition.find_by_condition_type_and_condition_value("publicity", "private")

    sets_hash.each_pair do |key, value|
      action = Action.find_by_action_type_and_action_value("view", key)
      if value == "public"
        condition_id = condition_public.id
      elsif value == "private"
        condition_id = condition_private.id
      end
      @rule.condition_action_sets.build(:condition_id => condition_id,
                                       :action_id => action.id)
    end

    if @rule.save
      return true
    else
      return false
    end
  end


  # added by ville
  def to_hash_by_data
    h = Hash.new
    condition_action_sets.each do |set|
      h[set.action.action_value] = set
    end
    return h
  end


  # added by ville
  def condition_action_sets_concerning(action_value)
    condition_action_sets.find(:all, :conditions => { :actions => { :action_value => action_value } }, :joins => [:action] ).inspect
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




  def to_json (asking_person, *a)
    rule_hash = get_rule_hash(asking_person)
    return rule_hash.to_json(*a)
  end

  # get all the condition_action_sets belong to this rule
  # return a hash of sets, empty hash if there is no set belong to this rule
  # return value: hash {action_obj1 => [condition_obj1, condition_obj2,...], action_obj2 => conditions_array, ...}
  def get_condition_action_sets_belong_to_the_rule
    sets = self.condition_action_sets
    sets_hash = {}

    if !(sets.empty?)
      sets.each do |set|
        action = set.action
        condition = set.condition
        if sets_hash.has_key?(action)
          conditions_array = sets_hash.fetch(action)
          conditions_array = conditions_array.push(condition)
          sets_hash[action] = conditions_array
        else
          conditions_array = [condition]
          sets_hash.merge!({action => conditions_array})
        end
      end
    end

    return sets_hash
  end


  # get all the condition_action_sets belong to this rule and corrsponding to
  # specific action_type and action_value
  # return an array of sets, empty array if there is no set
  def get_condition_action_sets_by_rule_action_type_value(action_type=nil, action_value=nil)
    ConditionActionSet.get_by_rule_id_action_type_action_value(self.id, action_type, action_value)
  end

  # check if subject_person has the right do a certain ation (action_type) to
  # data (action_value) based on this rule
  def authorize_according_to_one_rule(connection_person=nil, object_person_id=nil, action_type=nil, action_value=nil)
    #print "************ in rule/authorize_according_to_one_rule ******************* \n"
    #print "rule_id: #{self.id} , rule_name: #{self.rule_name}, person_id: #{self.person_id} \n"
    #print " "
    result = false
    condition_action_sets = self.get_condition_action_sets_by_rule_action_type_value(action_type, action_value)
    if condition_action_sets.length != 0
      condition_action_sets.each do |condition_action_set|
        condition = condition_action_set.condition
        #print "condition.id: #{condition.id}, condition.type: #{condition.condition_type}, condition.value: #{condition.condition_value} \n"
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
      return result
    end
    return true
  end

  private

  # check if the connection_person satisfies a condition
  def check_condition(connection_person=nil, object_person_id=nil, condition=nil)
    #print "************ in rule/check_condition ******************* \n"
    if condition
      condition_type = condition.condition_type
      condition_value = condition.condition_value
    end
    #print "condition_type:  #{condition_type} \n"
    #print "condition_value:  #{condition_value} \n"

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

    #print "check condition result: #{result} \n"
    return result
  end



  # check if connection_person is logged in
  # if condition_value is true, return true if connection_person is logged in
  # if condition_value is false, return true if connection_person is NOT logged_in
  def check_condition_logged_in(connection_person=nil, condition_value=nil)
    #print "************ in rule/check_condition_logged_in ******************* \n"
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
    #print "************ in rule/check_condition_group ******************* \n"
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
    #print "************ in rule/check_condition_friend ******************* \n"
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
    #print "************ in rule/check_condition_publicity ******************* \n"
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
    #print "************ in rule/check_condition_user ******************* \n"
    if !connection_person.nil? && !condition_value.nil?
      user = Person.find(:all, :conditions => {'username' => condition_value, 'id'=> connection_person.id})
      if user.length != 0
        return true
      end
    end

    return false
  end

end
