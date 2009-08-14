# == Schema Information
#
# Table name: transactions
#
#  id          :integer(4)      not null, primary key
#  sender_id   :integer(4)
#  receiver_id :integer(4)
#  listing_id  :integer(4)
#  amount      :integer(4)
#  description :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
