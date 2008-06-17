class CreateOwnerships < ActiveRecord::Migration
  def self.up
    create_table :ownerships do |t|
      t.string :collection_id
      t.string :item_id
      t.string :item_type
      t.timestamps
    end
  end

  def self.down
    drop_table :ownerships
  end
end
