class CreateDefaultConditions < ActiveRecord::Migration
  def self.up
    Condition.get_or_create(:condition_type => "publicity", :condition_value => "public")
    Condition.get_or_create(:condition_type => "publicity", :condition_value => "private")
    Condition.get_or_create(:condition_type => "publicity", :condition_value => "logged_in")
    Condition.get_or_create(:condition_type => "publicity", :condition_value => "friends_only")
  end

  def self.down
  end
end
