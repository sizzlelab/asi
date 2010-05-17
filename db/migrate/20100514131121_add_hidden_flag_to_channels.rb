class AddHiddenFlagToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :hidden, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :channels, :hidden
  end
end
