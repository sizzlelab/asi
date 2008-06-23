class CreatePersonNames < ActiveRecord::Migration
  def self.up
    create_table :person_names do |t|
      t.string :given_name, :default => ""
      t.string :family_name, :default => ""

      t.timestamps
    end
  end

  def self.down
    drop_table :person_names
  end
end
