class ConditionActionSet < ActiveRecord::Base
   belongs_to :condition # foreign key - condition_id
   belongs_to :action # foreign key - action_id
   belongs_to :rule # foreign key - rule_id

   validates_presence_of :condition, :action, :rule
end
