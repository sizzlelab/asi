class UserSubscription < ActiveRecord::Base
  belongs_to :channel
  belongs_to :person

  validates_uniqueness_of :person_id, :scope => :channel_id, :message => "is already subscribed to the channel."
end
