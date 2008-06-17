class CreateBinaryItems < ActiveRecord::Migration
  def self.up
    create_table :binary_items do |t|
      t.binary :data
      t.timestamps
    end
  end

  def self.down
    drop_table :binary_items
  end
end
