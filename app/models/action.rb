class Action < ActiveRecord::Base
  has_many :condition_action_sets
  has_many :conditions, :through => :condition_action_sets

  usesguid
  
  validates_presence_of [:action_type, :action_value]

  def Action.get_or_create(options)
    action = Action.find(:first, :conditions => options)
    if not action
      action = Action.new(options)
      if action.save
        return action
      end
    end

    return action
  end

end
