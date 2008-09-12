class RemoveContentTypeAndFilenameFromImage < ActiveRecord::Migration
  def self.up
    remove_column :images, :content_type
  end

  def self.down
    add_column :images, :content_type, :string
  end
end
