# == Schema Information
#
# Table name: conditions
#
#  id              :string(255)     default(""), not null, primary key
#  condition_type  :string(255)
#  condition_value :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#

require 'test_helper'

class ConditionTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
