class GroupSubscription < ActiveRecord::Base
  belongs_to :channel
  belongs_to :group
end
