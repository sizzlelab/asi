class DefaultNullToPersonGuid < ActiveRecord::Migration
  def self.up
    change_column :people, :guid, :string, { :null => true, :default => nil }
  end

  def self.down
    change_column :people, :guid, :string, { :null => true, :default => ""}
  end
end
