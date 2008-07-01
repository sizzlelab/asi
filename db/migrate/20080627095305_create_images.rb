class CreateImages < ActiveRecord::Migration
  def self.up
    create_table :images do |t|
      t.string :content_type
      t.string :filename
      t.binary :data, :limit => 50.megabytes
      t.binary :thumbnail, :limit => 1.megabytes

      t.timestamps
    end
  end

  def self.down
    drop_table :images
  end
end
