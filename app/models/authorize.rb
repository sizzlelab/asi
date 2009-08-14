# == Schema Information
#
# Table name: authorizes
#
#  id         :integer(4)      not null, primary key
#  person_id  :integer(4)
#  rule_id    :integer(4)
#  created_at :datetime
#  updated_at :datetime
#

class Authorize < ActiveRecord::Base
  belongs_to :person # foreign key - person_id
  belongs_to :rule # foreign key - rule_id
end
