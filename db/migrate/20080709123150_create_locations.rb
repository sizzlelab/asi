class CreateLocations < ActiveRecord::Migration
  def self.up
    create_table :locations do |t|
      t.string :person_id
      t.float :latitude
      t.float :longitude
      t.float :altitude
      t.float :vertical_accuracy
      t.float :horizontal_accuracy
      t.string :label

      t.timestamps
    end
  end

  def self.down
    drop_table :locations
  end
end
