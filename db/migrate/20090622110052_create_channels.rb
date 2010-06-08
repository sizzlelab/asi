class CreateChannels < ActiveRecord::Migration
  def self.up
    create_table :channels, :options => 'ENGINE=InnoDB' do |t|
      t.column :name, :string
      t.column :description, :string
      t.column :owner_id, :integer
      t.column :type, :string

      t.timestamps
    end
  end

  def self.down
    drop_table :channels
  end
end
