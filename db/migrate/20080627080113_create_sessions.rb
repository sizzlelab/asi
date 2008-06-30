class CreateSessions < ActiveRecord::Migration
  def self.up
    create_table :sessions do |t|
      t.belongs_to :person
      
      t.string :ip_address, :path
      t.timestamps
    end
    change_column :sessions, :person_id, :string # This is needed, because column created as int
  end
  
  def self.down
    drop_table :sessions
  end
end
