class CreateAuthorizes < ActiveRecord::Migration
  def self.up
    create_table :authorizes, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string :person_id
      t.integer :rule_id

      t.timestamps
    end
  end

  def self.down
    drop_table :authorizes
  end
end

