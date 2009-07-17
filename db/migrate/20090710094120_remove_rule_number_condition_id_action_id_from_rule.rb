class RemoveRuleNumberConditionIdActionIdFromRule < ActiveRecord::Migration
  def self.up
    remove_column :rules, :rule_number
    remove_column :rules, :condition_id
    remove_column :rules, :action_id
  end

  def self.down
    add_column :rules, :rule_number, :string
    add_column :rules, :condition_id, :string
    add_column :rules, :action_id, :string
  end
end
