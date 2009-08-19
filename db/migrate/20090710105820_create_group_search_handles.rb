class CreateGroupSearchHandles < ActiveRecord::Migration
  def self.up
    create_table :group_search_handles, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string :group_id
    end
  end

  def self.down
    drop_table :group_search_handles
  end
end
