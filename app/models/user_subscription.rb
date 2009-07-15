class UserSubscription < ActiveRecord::Base
  belongs_to :channel
  belongs_to :person
  
  validates_associated :channel
  validates_associated :person
end
