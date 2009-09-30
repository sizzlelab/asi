# == Schema Information
#
# Table name: feedbacks
#
#  id         :integer(4)      not null, primary key
#  content    :text
#  author_id  :string(255)
#  url        :string(255)
#  is_handled :integer(4)      default(0)
#  created_at :datetime
#  updated_at :datetime
#

require 'test_helper'

class FeedbackTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
