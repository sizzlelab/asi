class ChangeSemanticEventIdType < ActiveRecord::Migration
  def self.up
    change_column :cached_cos_events, :headers, :text
  end

  def self.down
    change_column :cached_cos_events, :headers, :string
  end
end
