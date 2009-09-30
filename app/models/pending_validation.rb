# == Schema Information
#
# Table name: pending_validations
#
#  id         :integer(4)      not null, primary key
#  person_id  :integer(4)
#  key        :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class PendingValidation < ActiveRecord::Base
  belongs_to :person
end
