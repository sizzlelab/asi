class RemoveThumbnailFromImage < ActiveRecord::Migration
  def self.up
    remove_column :images, :thumbnail
  end

  def self.down
    add_column :images, :thumbnail, :binary
  end
end
