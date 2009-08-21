class ConditionActionSet < ActiveRecord::Base
   belongs_to :condition # foreign key - condition_id
   belongs_to :action # foreign key - action_id
   belongs_to :rule # foreign key - rule_id

   validates_presence_of :condition, :action #:rule

  def ConditionActionSet.get_by_rule_id_action_type_action_value(rule_id=nil, action_type=nil, action_value=nil)
    ConditionActionSet.find(:all, :joins => [:action], :conditions => {'condition_action_sets.rule_id' => rule_id, 'actions.action_type' => action_type, 'actions.action_value' => action_value})
  end
end
