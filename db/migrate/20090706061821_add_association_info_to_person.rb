class AddAssociationInfoToPerson < ActiveRecord::Migration
  def self.up
    add_column :people, :is_association, :boolean
  end

  def self.down
    remove_column :people, :is_association
  end
end
