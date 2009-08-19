class CreateCachedCosEvents < ActiveRecord::Migration
  def self.up
    create_table :cached_cos_events, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string :user_id
      t.string :application_id
      t.string :cos_session_id
      t.string :ip_address
      t.string :action
      t.string :parameters
      t.string :return_value
      t.string :headers

      t.timestamps
    end
  end

  def self.down
    drop_table :cached_cos_events
  end
end
