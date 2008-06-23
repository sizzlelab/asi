class MoveEmailFromPersonSpecToPerson < ActiveRecord::Migration
  def self.up
    add_column :people, :email, :string
    remove_column :person_specs, :email
  end

  def self.down
    remove_column :people, :email
    add_column :person_specs, :email, :string
  end
end
