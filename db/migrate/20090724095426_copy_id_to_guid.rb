class CopyIdToGuid < ActiveRecord::Migration
  def self.up

    Person.reset_column_information

    Person.all.each do |p|
      p.update_attribute :guid, p.id
      p.save!
    end

  end

  def self.down
  end
end
