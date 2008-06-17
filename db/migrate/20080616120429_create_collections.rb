class CreateCollections < ActiveRecord::Migration
  def self.up
    create_table :collections, :id => false do |t|
      t.string :id
      t.boolean :read_only
      t.string :client_id
      t.timestamps
    end
    execute "ALTER TABLE collections ADD PRIMARY KEY (id)"
  end

  def self.down
    drop_table :collections
  end
end
