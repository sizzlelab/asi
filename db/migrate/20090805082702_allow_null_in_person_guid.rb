class AllowNullInPersonGuid < ActiveRecord::Migration
  def self.up
    change_column :people, :guid, :string, { :null => true }
  end

  def self.down
    change_column :people, :guid, :string, { :null => false }
  end
end
