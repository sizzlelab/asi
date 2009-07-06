class AddAssociationInfoToPersonSpec < ActiveRecord::Migration
  def self.up
    add_column :person_specs, :description, :string
    add_column :person_specs, :website, :string
  end

  def self.down
    remove_column :person_specs, :description
    remove_column :person_specs, :website
  end
end
