class AddSemanticEventId < ActiveRecord::Migration
  def self.up
    add_column :cached_cos_events, :semantic_event_id, :string
  end

  def self.down
    remove_column :cached_cos_events, :semantic_event_id
  end
end
