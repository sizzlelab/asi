class CreateActions < ActiveRecord::Migration
  def self.up
    create_table :actions, :id => false do |t|
      t.string :id
      t.string :model
      t.string :field

      t.timestamps
    end
    execute "ALTER TABLE actions ADD PRIMARY KEY (id)"
    end

  def self.down
    drop_table :actions
  end
end
