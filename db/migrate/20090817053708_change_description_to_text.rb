
class ChangeDescriptionToText < ActiveRecord::Migration
  def self.up
    change_column :people, :description, :text
  end

  def self.down
    change_column :people, :description, :string
  end
end
