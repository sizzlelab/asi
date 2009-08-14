# == Schema Information
#
# Table name: user_subscriptions
#
#  id         :integer(4)      not null, primary key
#  person_id  :integer(4)
#  channel_id :integer(4)
#  created_at :datetime
#  updated_at :datetime
#

class UserSubscription < ActiveRecord::Base
  belongs_to :channel
  belongs_to :person

  validates_uniqueness_of :person_id, :scope => :channel_id, :message => "is already subscribed to the channel."
end
