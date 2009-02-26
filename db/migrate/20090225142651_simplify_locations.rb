class SimplifyLocations < ActiveRecord::Migration
  def self.up
    remove_column :locations, :altitude
    remove_column :locations, :vertical_accuracy
    remove_column :locations, :horizontal_accuracy
    add_column :locations, :accuracy, :decimal, :precision => 15, :scale => 3
  end

  def self.down
    remove_column :locations, :accuracy
    add_column :locations, :altitude, :float
    add_column :locations, :vertical_accuracy, :float
    add_column :locations, :horizontal_accuracy, :decimal
  end
end
