class CreatePersonSpecs < ActiveRecord::Migration
  def self.up
    create_table :person_specs do |t|
      t.string :person_id
      t.string :email
      t.string :status_message, :default => ""
      t.date :birthdate
      t.string :gender

      t.timestamps
    end
  end

  def self.down
    drop_table :person_specs
  end
end
