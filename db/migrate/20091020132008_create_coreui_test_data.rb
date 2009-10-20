class CreateCoreuiTestData < ActiveRecord::Migration
  def self.up
    Client.create :name => COREUI_APP_NAME, :password => COREUI_APP_PASSWORD
  end

  def self.down
  end
end
