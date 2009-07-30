class ChangePersonIdsToIntegers < ActiveRecord::Migration
  def self.up
    Person.reset_column_information
    puts Person.count
    Person.all.each_with_index do |p, i|
      execute "UPDATE people SET id = '#{i+1}' WHERE id = '#{p.id}'"
    end
    Person.reset_column_information
    puts Person.count
  end

  def self.down
    Person.all.each do |p|
      p.id = p.guid
      p.save!
    end
  end
end
