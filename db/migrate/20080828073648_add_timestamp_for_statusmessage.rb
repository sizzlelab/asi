class AddTimestampForStatusmessage < ActiveRecord::Migration
  def self.up
    add_column :person_specs, :status_message_changed, :datetime
  end

  def self.down
    remove_column :person_specs, :status_message_changed
  end
end
