class AddOwnerToCollection < ActiveRecord::Migration
  def self.up
    add_column :collections, :owner_id, :string
  end

  def self.down
    remove_column :collections, :owner_id
  end
end
