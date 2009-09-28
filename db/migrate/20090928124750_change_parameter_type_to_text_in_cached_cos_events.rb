class ChangeParameterTypeToTextInCachedCosEvents < ActiveRecord::Migration
  def self.up
    change_column :cached_cos_events, :parameters, :text
  end

  def self.down
    change_column :cached_cos_events, :parameters, :string
  end
end
