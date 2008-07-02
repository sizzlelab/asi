class AddClientToSession < ActiveRecord::Migration
  def self.up
    add_column :sessions, :client_id, :string
  end

  def self.down
    remove_column :sessions, :client_id
  end
end
