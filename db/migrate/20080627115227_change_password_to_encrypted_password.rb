class ChangePasswordToEncryptedPassword < ActiveRecord::Migration
  def self.up
    rename_column :people, :password, :encrypted_password
  end

  def self.down
    rename_column :people, :encrypted_password, :password
  end
end
