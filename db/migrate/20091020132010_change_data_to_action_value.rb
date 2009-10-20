class ChangeDataToActionValue < ActiveRecord::Migration
  def self.up
    rename_column :actions, :data, :action_value
  end

  def self.down
    rename_column :actions, :action_value, :data
  end
end
