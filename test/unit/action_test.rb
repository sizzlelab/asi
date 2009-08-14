# == Schema Information
#
# Table name: actions
#
#  id         :string(255)     default(""), not null, primary key
#  model      :string(255)
#  field      :string(255)
#  created_at :datetime
#  updated_at :datetime
#

require 'test_helper'

class ActionTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
