class ChangeActionToActionType < ActiveRecord::Migration
  def self.up
    rename_column :actions, :action, :action_type
  end

  def self.down
    rename_column :actions, :action_type, :action
  end
end
