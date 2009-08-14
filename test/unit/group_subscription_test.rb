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

require 'test_helper'

class GroupSubscriptionTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
