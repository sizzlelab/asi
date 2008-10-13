class AddUpdatedByToCollections < ActiveRecord::Migration
  def self.up
    add_column :collections, :updated_by, :string
  end

  def self.down
    remove_column :collections, :updated_by
  end
end
