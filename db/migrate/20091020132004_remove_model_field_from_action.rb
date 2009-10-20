class RemoveModelFieldFromAction < ActiveRecord::Migration
  def self.up
    remove_column :actions, :model
    remove_column :actions, :field
  end

  def self.down
    add_column :actions, :model, :string
    add_column :actions, :field, :string
  end
end
