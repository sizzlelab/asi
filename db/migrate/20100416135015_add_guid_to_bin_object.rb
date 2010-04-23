class AddGuidToBinObject < ActiveRecord::Migration
  def self.up
    add_column :bin_objects, :guid, :string
  end

  def self.down
    remove_column :bin_objects, :guid
  end
end
