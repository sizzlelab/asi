class AddFilenameToBinaryItem < ActiveRecord::Migration
  def self.up
    add_column :binary_items, :filename, :string
  end

  def self.down
    remove_column :binary_items, :filename
  end
end
