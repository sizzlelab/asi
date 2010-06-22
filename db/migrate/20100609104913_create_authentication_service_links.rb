class CreateAuthenticationServiceLinks < ActiveRecord::Migration
  def self.up
    create_table :authentication_service_links do |t|
      t.references :person
      t.string :link

      t.timestamps
    end
  end

  def self.down
    drop_table :authentication_service_links
  end
end
