class AddIndestructibleToCollection < ActiveRecord::Migration
  def self.up
     add_column :collections, :indestructible, :boolean
   end

   def self.down
     remove_column :collections, :indestructible
   end
end
