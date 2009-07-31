class AddGuidToPerson < ActiveRecord::Migration
  def self.up
    add_column :people, :guid, :string, { :null => false }
    add_index :people, :guid
  end

  def self.down
    remove_column :people, :guid
  end
end
