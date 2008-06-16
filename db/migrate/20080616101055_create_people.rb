class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table :people, :id => false do |t|
      t.string :id
      t.string :username
      t.string :password

      t.timestamps
    end
    execute "ALTER TABLE people ADD PRIMARY KEY (id)"
  end

  def self.down
    drop_table :people
  end
end
