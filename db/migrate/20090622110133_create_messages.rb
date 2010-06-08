class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages, :options => 'ENGINE=InnoDB' do |t|
      t.column :title, :string
      t.column :content_type, :string
      t.column :body, :text
      t.column :poster_id, :integer
      t.column :channel_id, :integer

      t.timestamps
    end
  end

  def self.down
    drop_table :messages
  end
end
