class CorrectForeignKeyColumnTypes < ActiveRecord::Migration
  def self.up
    change_column :messages, :poster_id, :string
    change_column :messages, :channel_id, :string
    change_column :channels, :owner_id, :string
    change_column :channels, :id, :string
    change_column :user_subscriptions, :person_id, :string
    change_column :user_subscriptions, :channel_id, :string
    change_column :group_subscriptions, :channel_id, :string
    change_column :group_subscriptions, :group_id, :string
  end

  def self.down
    change_column :messages, :poster_id, :integer
    change_column :messages, :channel_id, :integer
    change_column :channels, :owner_id, :integer
    change_column :channels, :id, :integer
    change_column :user_subscriptions, :person_id, :integer
    change_column :user_subscriptions, :channel_id, :integer
    change_column :group_subscriptions, :channel_id, :integer
    change_column :group_subscriptions, :group_id, :integer
  end
end
