class Action < ActiveRecord::Base
  has_many :condition_action_sets
  has_many :conditions, :through => :condition_action_sets

  validates_presence_of [:action, :data]

  def Action.get_or_create(options)
    action = Action.find(:first, :conditions => { :action => options[:action], :data => options[:data] })
    if action.length == 0
      action = Action.new(:data => options[:action], :data => options[:data])
      if action.save
        return action
      end
    end

    return action
  end

end
