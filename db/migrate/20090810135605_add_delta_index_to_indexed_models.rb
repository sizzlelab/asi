class AddDeltaIndexToIndexedModels < ActiveRecord::Migration
  def self.up
    add_column :channels, :delta, :boolean, :default => true, :null => false
    add_column :group_search_handles, :delta, :boolean, :default => true, :null => false
    add_column :messages, :delta, :boolean, :default => true, :null => false
    add_column :people, :delta, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :channels, :delta, :boolean, :default => true, :null => false
    remove_column :group_search_handles, :delta, :boolean, :default => true, :null => false
    remove_column :messages, :delta, :boolean, :default => true, :null => false
    remove_column :people, :delta, :boolean, :default => true, :null => false
  end
end
