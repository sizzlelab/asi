# == Schema Information
#
# Table name: conditions
#
#  id              :string(255)     default(""), not null, primary key
#  condition_type  :string(255)
#  condition_value :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#

class Condition < ActiveRecord::Base
  has_many :rules
  has_many :actions, :through => :rules

  validates_presence_of :type, :value
end
