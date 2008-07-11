class AddMetadataToCollection < ActiveRecord::Migration
  def self.up
    add_column :collections, :metadata, :text
  end

  def self.down
    remove_column :collections, :metadata
  end
end
