class CreateGroupSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :group_subscriptions do |t|
      t.column :group_id, :integer
      t.column :channel_id, :integer
      
      t.timestamps
    end
  end

  def self.down
    drop_table :group_subscriptions
  end
end
