class DropOrphans < ActiveRecord::Migration

  def self.up
    Connection.all.each do |c|
      if ! Person.find_by_id(c.person_id) || ! Person.find_by_id(c.contact_id)
        c.destroy
      end
    end

    [ PendingValidation, PersonName, PersonSpec, Role, Session ].each do |k|
      k.all.each do |c|
        if ! Person.find_by_id(c.person_id)
          c.destroy
        end
      end
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
