class CreateAddresses < ActiveRecord::Migration
  def self.up
    create_table :addresses do |t|
      t.string :street_address
      t.string :postal_code
      t.string :locality
      t.string :owner_id
      t.string :owner_type

      t.timestamps
    end
  end

  def self.down
    drop_table :addresses
  end
end
