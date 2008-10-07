class AddTagsToCollection < ActiveRecord::Migration
  def self.up
    add_column :collections, :tags, :string
  end

  def self.down
    remove_column :collections, :tags
  end
end