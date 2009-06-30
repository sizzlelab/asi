class Authorize < ActiveRecord::Base
  belongs_to :person # foreign key - person_id
  belongs_to :rule # foreign key - rule_id
end
