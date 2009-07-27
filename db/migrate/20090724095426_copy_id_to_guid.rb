class CopyIdToGuid < ActiveRecord::Migration
  def self.up
    Person.all.each do |p|
      p.guid = p.id
      p.save(false)
    end
  end

  def self.down
  end
end
