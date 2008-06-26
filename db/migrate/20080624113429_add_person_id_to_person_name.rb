class AddPersonIdToPersonName < ActiveRecord::Migration
  def self.up
    add_column :person_names, :person_id, :string
  end

  def self.down
    remove_column :person_names, :person_id
  end
end
