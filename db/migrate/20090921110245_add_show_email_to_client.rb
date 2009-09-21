class AddShowEmailToClient < ActiveRecord::Migration
  def self.up
    add_column :clients, :show_email, :boolean
  end

  def self.down
    remove_column :clients, :show_email
  end
end
