class AddSaltToPerson < ActiveRecord::Migration
  def self.up
    add_column :people, :salt, :string
    Person.find(:all).each { |people| people.update_attribute :salt, [Array.new(9){rand(256).chr}.join].pack('m').chomp}
  end
  def self.down
    remove_column :people, :salt
  end
end
