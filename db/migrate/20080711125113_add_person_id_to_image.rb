class AddPersonIdToImage < ActiveRecord::Migration
  def self.up
    add_column :images, :person_id, :string
  end

  def self.down
    remove_column :images, :person_id
  end
end
