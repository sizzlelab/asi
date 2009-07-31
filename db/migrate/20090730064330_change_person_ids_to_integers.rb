class ChangePersonIdsToIntegers < ActiveRecord::Migration
  def self.up
    Person.reset_column_information

    Person.all.each_with_index do |p, i|
      execute "UPDATE people SET id = '#{i+1}' WHERE id = '#{p.id}'"
    end
  end

  def self.down
    Person.all.each do |p|
      p.id = p.guid
      p.save!
    end
  end
end
