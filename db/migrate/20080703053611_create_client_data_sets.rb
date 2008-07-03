class CreateClientDataSets < ActiveRecord::Migration
  def self.up
    create_table :client_data_sets do |t|
      t.string :client_id
      t.string :person_id

      t.timestamps
    end
  end

  def self.down
    drop_table :client_data_sets
  end
end
