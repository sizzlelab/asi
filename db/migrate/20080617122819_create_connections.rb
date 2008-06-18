class CreateConnections < ActiveRecord::Migration
  def self.up
    create_table :connections do |t|
      t.string :person_id
      t.string :contact_id
      t.string :status

      t.timestamps
    end
  end

  def self.down
    drop_table :connections
  end
end
