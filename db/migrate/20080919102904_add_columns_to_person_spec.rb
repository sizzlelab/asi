class AddColumnsToPersonSpec < ActiveRecord::Migration
  def self.up
    add_column :person_specs, :unstructured_address, :string 
    add_column :person_specs, :irc_nick, :string 
    add_column :person_specs, :msn_nick, :string 
    add_column :person_specs, :phone_number, :string
  end

  def self.down
    remove_column :person_specs, :unstructured_address
    remove_column :person_specs, :irc_nick
    remove_column :person_specs, :msn_nick
    remove_column :person_specs, :phone_number
  end
end
