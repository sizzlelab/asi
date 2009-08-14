# == Schema Information
#
# Table name: authorizes
#
#  id         :integer(4)      not null, primary key
#  person_id  :integer(4)
#  rule_id    :integer(4)
#  created_at :datetime
#  updated_at :datetime
#

require 'test_helper'

class AuthorizeTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
