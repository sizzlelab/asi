class ChannelAndMessageGuidsAndIds < ActiveRecord::Migration
  def self.up
    add_column :channels, :guid, :string
    change_column :channels, :id, :integer, { :default => "0" }
    change_column :group_subscriptions, :channel_id, :integer
    change_column :user_subscriptions, :channel_id, :integer
    change_column :messages, :channel_id, :integer
    
    add_column :messages, :guid, :string
    execute "ALTER TABLE channels CHANGE id id INTEGER AUTO_INCREMENT;"
  end

  def self.down
    change_column :channels, :id, :string
    remove_column :channels, :guid
    change_column :user_subscriptions, :channel_id, :string
    change_column :group_subscriptions, :channel_id, :string
    change_column :messages, :channel_id, :string
    
    remove_column :messages, :guid
  end
end
