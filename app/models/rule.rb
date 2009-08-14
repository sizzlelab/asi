# == Schema Information
#
# Table name: rules
#
#  id           :string(255)     default(""), not null, primary key
#  rule_number  :string(255)
#  condition_id :integer(4)
#  action_id    :integer(4)
#  created_at   :datetime
#  updated_at   :datetime
#

class Rule < ActiveRecord::Base
  belongs_to :conditions # foreign key - condition_id
  belongs_to :actions #foreign key - action_id
  has_many :persons,
           :through => :authorizes
  has_many :authorizes
end
