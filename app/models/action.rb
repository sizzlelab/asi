class Action < ActiveRecord::Base
  has_many :condition_action_sets
  has_many :conditions, :through => :condition_action_sets

  validates_presence_of [:action_type, :action_data]

  def Action.get_or_create(options)
    action = Action.find(:first, :conditions => { :action_type => options[:action_type], :action_value => options[:action_value] })
    if action.length == 0
      action = Action.new(:action_type=> options[:action_type], :action_value => options[:action_value])
      if action.save
        return action
      end
    end

    return action
  end

end
