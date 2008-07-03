class CreateClientDataPairs < ActiveRecord::Migration
  def self.up
    create_table :client_data_pairs do |t|
      t.string :key
      t.string :value
      t.integer :client_data_set_id

      t.timestamps
    end
  end

  def self.down
    drop_table :client_data_pairs
  end
end
