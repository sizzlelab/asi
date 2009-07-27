class CopyPersonSpecDataToPerson < ActiveRecord::Migration
  def self.up
    PersonSpec.all.each do |spec|
      spec.attributes.each do |attribute|
        unless attribute[0].end_with? "id"
          spec.person.update_attribute *attribute
          spec.person.save
        end
      end
    end
  end

  def self.down
  end
end
