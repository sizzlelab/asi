class ConditionActionSet < ActiveRecord::Base
   belongs_to :condition # foreign key - condition_id
   belongs_to :action # foreign key - action_id
   belongs_to :rule # foreign key - rule_id

   validates_presence_of :condition, :action #:rule

  def ConditionActionSet.get_by_rule_id_action_data(rule_id=nil, action=nil, data=nil)
    ConditionActionSet.find(:all, :joins => [:action], :conditions => {'condition_action_sets.rule_id' => rule_id, 'actions.action' => action, 'actions.data' => data})
  end
end
