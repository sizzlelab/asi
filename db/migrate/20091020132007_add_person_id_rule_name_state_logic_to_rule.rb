class AddPersonIdRuleNameStateLogicToRule < ActiveRecord::Migration
  def self.up
    add_column :rules, :person_id, :string
    add_column :rules, :rule_name, :string
    add_column :rules, :state, :string
    add_column :rules, :logic, :string, :default => "And"
  end

  def self.down
    remove_column :rules, :person_id
    remove_column :rules, :rule_name
    remove_column :rules, :state
    remove_column :rules, :logic
  end
end
