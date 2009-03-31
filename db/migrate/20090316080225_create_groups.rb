class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table :groups, :id => false do |t|
      t.string :id
      t.string :title
      t.string :created_by
      t.string :group_type
      t.timestamps
    end
    
    execute "ALTER TABLE groups ADD PRIMARY KEY (id)"
    
    create_table :memberships do |t|
      t.string :person_id, :null => false
      t.string :group_id, :null => false
      t.datetime :accepted_at
      t.boolean :admin_role, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :groups
    drop_table :memberships
  end
end
