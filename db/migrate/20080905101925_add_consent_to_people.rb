class AddConsentToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :consent, :string
  end

  def self.down
    remove_column :people, :consent
  end
end
