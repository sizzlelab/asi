class AddDescriptionToGroups < ActiveRecord::Migration
  def self.up
     add_column :groups, :description, :text
     add_column :memberships, :status, :string
     add_column :memberships, :inviter_id, :string
  end

  def self.down
    remove_column :groups, :description
    remove_column :memberships, :status
    remove_column :memberships, :inviter_id
  end
end
