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

require 'test_helper'

class UserSubscriptionTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
