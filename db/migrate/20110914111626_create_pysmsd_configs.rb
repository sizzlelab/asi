class CreatePysmsdConfigs < ActiveRecord::Migration
  def self.up
    create_table :pysmsd_configs, :options => 'ENGINE=InnoDB' do |t|
      t.column :enabled, :boolean, :default=>0
      t.column :app_name, :string, :default=> nil
      t.column :app_password, :string, :default=> nil
      t.column :host, :string, :default=> nil
      t.column :port, :integer, :default=> nil
      t.column :use_ssl,:boolean, :default=>1
      t.column :number, :string, :default=>nil
      t.column :use_proxy, :boolean, :default=>0
      t.column :proxy_host, :string, :default=>nil
      t.column :proxy_port, :integer, :default=>nil
      t.column :proxy_username, :string, :default=>nil
      t.column :proxy_password, :string, :default=>nil
      t.column :client_id, :string
      t.timestamps
      
    end
    add_index :pysmsd_configs, :client_id, :unique => true, :name => "client_id_unique_index"
  end

  def self.down
    remove_index :pysmsd_configs, :name => "client_id_unique_index"
    drop_table :pysmsd_configs
  end
end
