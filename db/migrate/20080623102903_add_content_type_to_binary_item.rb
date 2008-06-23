class AddContentTypeToBinaryItem < ActiveRecord::Migration
  def self.up
    add_column :binary_items, :content_type, :string
  end

  def self.down
    remove_column :binary_items, :content_type
  end
end
