class AddActionDataToAction < ActiveRecord::Migration
  def self.up
    add_column :actions, :action, :string
    add_column :actions, :data, :string
  end

  def self.down
    remove_column :actions, :action
    remove_column :actions, :data
  end
end
