class AddSmallThumbAndLargeThumbToImage < ActiveRecord::Migration
  def self.up
    add_column :images, :small_thumb, :binary
    add_column :images, :large_thumb, :binary
  end

  def self.down
    remove_column :images, :small_thumb
    remove_column :images, :large_thumb
  end
end
