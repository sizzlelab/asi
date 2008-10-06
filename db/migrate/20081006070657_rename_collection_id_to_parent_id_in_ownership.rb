class RenameCollectionIdToParentIdInOwnership < ActiveRecord::Migration
  def self.up
    rename_column :ownerships, :collection_id, :parent_id
  end

  def self.down
    rename_column :ownerships, :parent_id, :collection_id
  end
end
