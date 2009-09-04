class AddRealnameToClients < ActiveRecord::Migration
  def self.up
    add_column :clients, :realname, :string
  end

  def self.down
    remove_column :clients, :realname
  end
end
