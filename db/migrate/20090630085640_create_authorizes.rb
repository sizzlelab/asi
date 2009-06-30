class CreateAuthorizes < ActiveRecord::Migration
  def self.up
    create_table :authorizes do |t|
      t.string :person_id
      t.integer :rule_id

      t.timestamps
    end
  end

  def self.down
    drop_table :authorizes
  end
end

