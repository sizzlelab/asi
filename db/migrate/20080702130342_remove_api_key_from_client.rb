class RemoveApiKeyFromClient < ActiveRecord::Migration
  def self.up
    remove_column :clients, :api_key
  end

  def self.down
    add_column :clients, :api_key, :string
  end
end
