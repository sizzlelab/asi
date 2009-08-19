class CreateRules < ActiveRecord::Migration
  def self.up
    create_table :rules, :id => false, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string :id
      t.string :rule_number
      t.integer :condition_id
      t.integer :action_id

      t.timestamps
    end
    execute "ALTER TABLE rules ADD PRIMARY KEY (id)"
  end

  def self.down
    drop_table :rules
  end
end
