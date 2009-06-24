class UserSubscription < ActiveRecord::Base
  belongs_to :channel
  belongs_to :person
end
