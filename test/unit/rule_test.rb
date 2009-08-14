# == Schema Information
#
# Table name: rules
#
#  id           :string(255)     default(""), not null, primary key
#  rule_number  :string(255)
#  condition_id :integer(4)
#  action_id    :integer(4)
#  created_at   :datetime
#  updated_at   :datetime
#

require 'test_helper'

class RuleTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
