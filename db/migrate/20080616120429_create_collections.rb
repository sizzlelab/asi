class CreateCollections < ActiveRecord::Migration
  def self.up
    create_table :collections do |t|
      t.boolean :read_only

      t.timestamps
    end
  end

  def self.down
    drop_table :collections
  end
end
