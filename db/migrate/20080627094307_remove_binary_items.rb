class RemoveBinaryItems < ActiveRecord::Migration
  def self.up
    drop_table :binary_items
  end

  def self.down
    create_table :binary_items do |t|
      t.binary :data
      t.string :content_type
      t.string :filename
      
      t.timestamps
    end
  end
end
