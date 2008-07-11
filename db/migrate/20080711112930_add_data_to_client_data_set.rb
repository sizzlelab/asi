class AddDataToClientDataSet < ActiveRecord::Migration
  def self.up
    add_column :client_data_sets, :data, :text
  end

  def self.down
    remove_column :client_data_sets, :data
  end
end
