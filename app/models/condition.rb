class Condition < ActiveRecord::Base
  has_many :rules
  has_many :actions, :through => :rules

  validates_presence_of :type, :value
end
