class CreateConditionActionSets < ActiveRecord::Migration
  def self.up
    create_table :condition_action_sets do |t|
        t.string :condition_id
        t.string :action_id
        t.string :rule_id
        
      t.timestamps
    end
  end

  def self.down
    drop_table :condition_action_sets
  end
end
