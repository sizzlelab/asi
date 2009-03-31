class RemoveUnstructuredAddressFromPersonSpec < ActiveRecord::Migration
  def self.up
    remove_column :person_specs, :unstructured_address
  end

  def self.down
    add_column :person_specs, :unstructured_address, :string
  end
end
