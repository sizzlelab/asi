class AddGuidToImageAndTextItem < ActiveRecord::Migration
  def self.up
    drop_table :images
    drop_table :text_items 
    create_table :images, :id => false do |t|
      t.string :id
      t.string :content_type
      t.string :filename
      t.binary :data, :limit => 50.megabytes
      t.binary :thumbnail, :limit => 1.megabytes
      t.timestamps
    end
    execute "ALTER TABLE images ADD PRIMARY KEY (id)"
    create_table :text_items, :id => false do |t|
      t.string :id
      t.text :text
      t.timestamps
    end
    execute "ALTER TABLE text_items ADD PRIMARY KEY (id)"
  end

  def self.down
    drop_table :images
    drop_table :text_items
    create_table :images do |t|
      t.string :content_type
      t.string :filename
      t.binary :data, :limit => 50.megabytes
      t.binary :thumbnail, :limit => 1.megabytes
      t.timestamps
    end
    create_table :text_items do |t|
      t.text :text
      t.timestamps
    end
  end
end