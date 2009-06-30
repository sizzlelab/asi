class Action < ActiveRecord::Base
  has_many :rules
  has_many :conditions, :through => :rules

  validates_presence_of :model
end
