class AddSourceInstallationToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :source_installation, :string
    Person.reset_column_information
    Person.find(:all).each do |p|
      p.update_attribute :source_installation, APP_CONFIG.source_installation
    end
  end

  def self.down
    remove_column :people, :source_installation
  end
end
