class CreateConditions < ActiveRecord::Migration
  def self.up
    create_table :conditions, :id => false do |t|
      t.string :id
      t.string :condition_type
      t.string :condition_value

      t.timestamps
    end
    execute "ALTER TABLE conditions ADD PRIMARY KEY (id)"
    end

  def self.down
    drop_table :conditions
  end
end
