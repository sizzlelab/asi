class CreateUserSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :user_subscriptions, :options => 'ENGINE=InnoDB' do |t|
      t.column :person_id, :integer
      t.column :channel_id, :integer

      t.timestamps
    end
  end

  def self.down
    drop_table :user_subscriptions
  end
end
