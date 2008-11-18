class AddCoinAmountToPerson < ActiveRecord::Migration
  def self.up
    add_column :people, :coin_amount, :integer, :null => false, :default => 0 
  end

  def self.down
    remove_column :people, :coin_amount
  end
end
