class ChangeCoordinatesToDecimals < ActiveRecord::Migration
  def self.up
    change_column :locations , :latitude, :decimal, :precision => 15, :scale => 12
    change_column :locations , :longitude, :decimal, :precision => 15, :scale => 12
    change_column :locations , :horizontal_accuracy, :decimal, :precision => 15, :scale => 12
  end

  def self.down
    change_column :locations , :latitude, :float
    change_column :locations , :longitude, :float
    change_column :locations , :horizontal_accuracy, :float
  end
end
