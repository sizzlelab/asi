class Condition < ActiveRecord::Base
  has_many :condition_action_sets
  has_many :actions, :through => :condition_action_sets

  validates_presence_of [:condition_type, :condition_value]
end
