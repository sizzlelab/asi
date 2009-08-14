# == Schema Information
#
# Table name: group_subscriptions
#
#  id         :integer(4)      not null, primary key
#  group_id   :string(255)
#  channel_id :integer(4)
#  created_at :datetime
#  updated_at :datetime
#

class GroupSubscription < ActiveRecord::Base
  belongs_to :channel
  belongs_to :group

  validates_uniqueness_of :group_id, :scope => :channel_id, :message => "is already subscribed to the channel."
end
