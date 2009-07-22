class GroupSubscription < ActiveRecord::Base
  belongs_to :channel
  belongs_to :group

  validates_uniqueness_of :group_id, :scope => :channel_id, :message => "is already subscribed to the channel."
end
