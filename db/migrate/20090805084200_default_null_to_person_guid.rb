class DefaultNullToPersonGuid < ActiveRecord::Migration
  def self.up
    change_column :person, :guid, :string, { :null => true, :default => NULL}
  end

  def self.down
    change_column :person, :guid, :string, { :null => true, :default => ""}
  end
end
