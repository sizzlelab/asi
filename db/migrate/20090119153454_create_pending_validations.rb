class CreatePendingValidations < ActiveRecord::Migration
  def self.up
    create_table :pending_validations do |t|
      t.string :person_id
      t.string :key

      t.timestamps
    end
  end

  def self.down
    drop_table :pending_validations
  end
end
