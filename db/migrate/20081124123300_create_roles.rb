class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles do |t|
      t.string :person_id
      t.string :client_id
      t.string :title

      t.timestamps
    end
  end

  def self.down
    drop_table :roles
  end
end
