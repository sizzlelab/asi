class AddLocationSecurityTokenToRoles < ActiveRecord::Migration
  def self.up
    add_column :roles, :location_security_token, :string
  end

  def self.down
    remove_column :roles, :location_security_token, :string
  end
end
