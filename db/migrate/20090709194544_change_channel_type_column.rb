class ChangeChannelTypeColumn < ActiveRecord::Migration
  def self.up
    rename_column :channels, :type, :channel_type
  end

  def self.down
    rename_column :channels, :channel_type, :type
  end
end
