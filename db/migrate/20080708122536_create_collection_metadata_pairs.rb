class CreateCollectionMetadataPairs < ActiveRecord::Migration
  def self.up
    create_table :collection_metadata_pairs do |t|
      t.string :key
      t.string :value
      t.string :collection_id

      t.timestamps
    end
  end

  def self.down
    drop_table :collection_metadata_pairs
  end
end
