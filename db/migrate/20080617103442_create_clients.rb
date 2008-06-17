class CreateClients < ActiveRecord::Migration
  def self.up
    create_table :clients, :id => false do |t|
      t.string :id
      t.string :name
      t.string :api_key
      t.timestamps
    end
    execute "ALTER TABLE clients ADD PRIMARY KEY (id)"
  end

  def self.down
    drop_table :clients
  end
end
