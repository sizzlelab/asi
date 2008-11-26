class AddPrivateToCollection < ActiveRecord::Migration
  def self.up
    add_column :collections, :private, :boolean
    Collection.reset_column_information
    Collection.all( :conditions => "owner_id IS NOT NULL").each do |collection|
      collection.private = true
      collection.save
    end
  end

  def self.down
    remove_column :collections, :private
  end
end

