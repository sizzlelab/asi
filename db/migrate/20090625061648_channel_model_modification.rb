class ChannelModelModification < ActiveRecord::Migration
  def self.up
    add_column :messages, :reference_to, :integer
    add_column :messages, :attachment, :string
    add_column :channels, :creator_app_id, :string
  end

  def self.down
    remove_column :messages, :reference_to
    remove_column :messages, :attachment
    remove_column :channels, :creator_app_id
  end
end
