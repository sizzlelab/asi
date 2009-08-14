# == Schema Information
#
# Table name: actions
#
#  id         :string(255)     default(""), not null, primary key
#  model      :string(255)
#  field      :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Action < ActiveRecord::Base
  has_many :rules
  has_many :conditions, :through => :rules

  validates_presence_of :model
end
