class CopyPersonSpecDataToPerson < ActiveRecord::Migration
  def self.up
    Person.reset_column_information
    PersonSpec.all.reject{ |s| s.person == nil }.each do |spec|
      spec.attributes.each do |attribute|
        unless attribute[0].end_with? "id" || attribute[0] == "guid"
          spec.person.update_attribute *attribute
          spec.person.save
        end
      end
    end
  end

  def self.down
  end
end
