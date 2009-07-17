class Rule < ActiveRecord::Base
  has_many :condition_action_sets
  belongs_to :person # foreign_key - person_id

   validates_presence_of :person
   validates_presence_of [:rule_name, :state, :logic]
   
   def get_rule_hash()

  end


   def find_by_object_person_id(object_person_id)
     
   end

   # added by tchang
   # check if subject_person has access right to model and field
   # syntax: authorize?(subject_person_id, object_person_id, action, field)
   # return: true or false
  def Rule.authorize?(connection_person_id=nil, object_person_id=nil, action=nil, data=nil)
     print "************ in rule/authorize? ******************* \n"
     if connection_person
       print "connection_person.id: #{connection_person.id} \n"
     end
     print "action: #{action} \n"
     print "data: #{data} \n"

    result = false

   if (action && data)
      # both params action and data are not nil, find action_id
      action_item = Action.find(:first, :conditions => {'action' => action,'data' => data})
       print "action.id: #{action_item.id} \n"
    else
      return result
    end

    # find all the rules associated with object_person and action_item
    rules = Rule.find(:all, :joins => :authorizes, :conditions => {'authorizes.person_id' => object_person_id, 'rules.action_id' => action.id})

    # must satisfy all the conditions
    if rules.length != 0
      rules.each do |rule|
        print "rule.id: #{rule.id}, rule.rule_number: #{rule.rule_number}, rule.condition_id: #{rule.condition_id}, rule.action_id: #{rule.action_id} \n"
        condition = Condition.find_by_id(rule.condition_id)
        print "condition.id: #{condition.id}, condition.type: #{condition.condition_type}, condition.value: #{condition.condition_value} \n"

        if check_condition(connection_person, condition)
          result = true
        else
          result = false
          return result
        end
      end
    end

    return result
  end


  

  private

  #
  def check_condition(connection_person=nil, condition=nil)
    print "************ in rule/check_condition ******************* \n"
    if connection_person
      print "connection_person.id:  #{connection_person.id} \n"
    end
    print "condition.id:  #{condition.id} \n"

    result = false
    condition_type = condition.condition_type
    condition_value = condition.condition_value
    print "condition_type:  #{condition_type} \n"
    print "condition_value:  #{condition_value} \n"

    case condition_type
    when "Logged_in"
      check_condition_logged_in(connection_person, condition_value)
    when "Group"
      check_condition_group(connection_person, condition_value)
    when "Is_friend"
     check_condition_friend(connection_person, condition_value)
    when "Public"
      check_condition_every_one(connection_person, condition_value)
    when "Private"
      check_condition_private(connection_person, condition_value)
    when "User"
      check_condition_user(connection_person, condition_value)
      #more condition types can go here
    end

    print "check condition result: #{result} \n"
    return result
  end



  #
  def check_condition_logged_in(connection_person, condition_value)
    if condition_value
        if connection_person != nil
         return true
        else
          return false
        end
      else
        if connection_person == nil
          return true
        else
          return false
        end
      end
  end



  # check if connection_person is a member of the group
  def check_condition_group(connection_person, condition_value)
    if connection_person & condition_value
        mems = Membership.find(:all, :conditions => ['group_id = ? AND person_id = ? ', condition_value, connection_person.id]) #AND status = ?
        if mems.length != 0
          return true
        end
      end

    return false
  end



  # check if connection_person is a friend of object_person
  def check_condition_friend(connection_person, condition_value)
    if connection_person & condition_value
      friend = Connection.find(:all, :conditions => ['person_id = ? AND contact_id = ? AND status = ?', condition_value, connection_person.id])
    end
  end



   # every user can perform the action
  def check_condition_public(connection_person, condition_value)
    if condition_value
      return true
    end
  end


  
   # only the user himslef can perform the action
  def check_condition_private(connection_person, condition_value)
    if condition_value
        return (connection_person == self)
      end
  end

   # only a specific user can perform the action
   # condition_value is the username
  def check_condition_user(connection_person, condition_value)
    if connection_person & condition_value
      user = Person.find(:all, :conditions => ['username = ?', condition_value])
      if user && user.id == connection_person.id
        retrun true
      end
    end

    return false
  end

end
