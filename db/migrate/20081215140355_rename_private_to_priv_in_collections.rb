class RenamePrivateToPrivInCollections < ActiveRecord::Migration
  def self.up
    rename_column :collections, :private, :priv
  end

  def self.down
    rename_column :collections, :priv, :private
  end
end
