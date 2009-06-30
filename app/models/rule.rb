class Rule < ActiveRecord::Base
  belongs_to :conditions # foreign key - condition_id
  belongs_to :actions #foreign key - action_id
  has_many :persons,
           :through => :authorizes
  has_many :authorizes
end
