class ChangePersonIdToInteger < ActiveRecord::Migration
  def self.up
    drop_foreign_key :addresses, :people
    drop_foreign_key :authorizes, :people
    drop_foreign_key :channels, :people
    drop_foreign_key :client_data_sets, :people
    drop_foreign_key :collections, :people
    drop_foreign_key :connections, :people, "person"
    drop_foreign_key :connections, :people, "contact"
    drop_foreign_key :groups, :people
    drop_foreign_key :images, :people
    drop_foreign_key :locations, :people
    drop_foreign_key :memberships, :people, "person"
    drop_foreign_key :memberships, :people, "inviter"
    drop_foreign_key :messages, :people
    drop_foreign_key :pending_validations, :people
    drop_foreign_key :person_names, :people
    drop_foreign_key :person_specs, :people
    drop_foreign_key :roles, :people
    drop_foreign_key :sessions, :people
    drop_foreign_key :transactions, :people, "sender"
    drop_foreign_key :transactions, :people, "receiver"
    drop_foreign_key :user_subscriptions, :people

    execute "ALTER TABLE people CHANGE id id INTEGER AUTO_INCREMENT;"

    change_column :memberships, :person_id, :integer, { :default => 0 }
    change_column :memberships, :inviter_id, :integer
    change_column :addresses, :owner_id, :integer
    change_column :authorizes, :person_id, :integer
    change_column :channels, :owner_id, :integer
    change_column :client_data_sets, :person_id, :integer
    change_column :collections, :owner_id, :integer
    change_column :connections, :person_id, :integer
    change_column :connections, :contact_id, :integer
    change_column :groups, :created_by, :integer
    change_column :images, :person_id, :integer
    change_column :locations, :person_id, :integer
    change_column :messages, :poster_id, :integer
    change_column :pending_validations, :person_id, :integer
    change_column :person_names, :person_id, :integer
    change_column :person_specs, :person_id, :integer
    change_column :roles, :person_id, :integer
    change_column :sessions, :person_id, :integer
    change_column :transactions, :sender_id, :integer
    change_column :transactions, :receiver_id, :integer
    change_column :user_subscriptions, :person_id, :integer


    foreign_key :memberships, :person_id, :people, :id, "person"
    foreign_key :memberships, :inviter_id, :people, :id, "inviter"
    foreign_key :addresses, :owner_id, :people, :id
    foreign_key :authorizes, :person_id, :people, :id
    foreign_key :channels, :owner_id, :people, :id
    foreign_key :client_data_sets, :person_id, :people, :id
    foreign_key :collections, :owner_id, :people, :id
    foreign_key :connections, :person_id, :people, :id, "person"
    foreign_key :connections, :contact_id, :people, :id, "contact"
    foreign_key :groups, :created_by, :people, :id
    foreign_key :images, :person_id, :people, :id
    foreign_key :locations, :person_id, :people, :id
    foreign_key :messages, :poster_id, :people, :id
    foreign_key :pending_validations, :person_id, :people, :id
    foreign_key :person_names, :person_id, :people, :id
    foreign_key :person_specs, :person_id, :people, :id
    foreign_key :roles, :person_id, :people, :id
    foreign_key :sessions, :person_id, :people, :id
    foreign_key :transactions, :sender_id, :people, :id, "sender"
    foreign_key :transactions, :receiver_id, :people, :id, "receiver"
    foreign_key :user_subscriptions, :person_id, :people, :id


  end

  def self.down
  end

  def self.foreign_key(from_table, from_column, to_table, to_column, suffix=nil, on_delete='SET NULL', on_update='CASCADE')
    constraint_name = "fk_#{from_table}_#{to_table}"
    constraint_name += "_#{suffix}" unless suffix.nil?
    execute %{alter table #{from_table}
     add constraint #{constraint_name}
     foreign key (#{from_column})
     references #{to_table}(#{to_column})
     on delete #{on_delete}
     on update #{on_update}
   }
  end

  def self.drop_foreign_key(from_table, to_table, suffix=nil)
    constraint_name = "fk_#{from_table}_#{to_table}"
    constraint_name += "_#{suffix}" unless suffix.nil?
    execute "alter table #{from_table} drop foreign key #{constraint_name}"
    execute "alter table #{from_table} drop key #{constraint_name}"
  end

end
