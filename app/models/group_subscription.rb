class GroupSubscription < ActiveRecord::Base
  belongs_to :channel
  belongs_to :group
  
  validates_associated :channel
  validates_associated :group
end
