class AddConsentToRoles < ActiveRecord::Migration
  def self.up
    add_column :roles, :terms_version, :string
  end

  def self.down
    remove_column :roles, :terms_version
  end
end
