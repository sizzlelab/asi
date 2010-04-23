class CreateBinObjects < ActiveRecord::Migration
  def self.up
    create_table :bin_objects do |t|
      t.column :name, :string
      t.column :data, :binary, :limit => 50.megabytes
      t.column :content_type, :string
      t.column :orig_name, :string
      t.column :poster_id, :integer

      t.timestamps
    end
  end

  def self.down
    drop_table :bin_objects
  end
end
