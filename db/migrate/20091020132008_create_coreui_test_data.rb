class CreateCoreuiTestData < ActiveRecord::Migration
  def self.up
    Client.create :name => APP_CONFIG.coreui_app_name, :password => APP_CONFIG.coreui_app_password
  end

  def self.down
  end
end
