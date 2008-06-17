class CreateTextItems < ActiveRecord::Migration
  def self.up
    create_table :text_items do |t|
      t.text :text
      t.timestamps
    end
  end

  def self.down
    drop_table :text_items
  end
end
