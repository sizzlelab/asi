require 'test_helper'

class GroupSearchHandleTest < ActiveSupport::TestCase

  test "search" do
    result = GroupSearchHandle.search "group"

    assert_not_equal 0, result.size, "Found nothing"
    assert_not_equal Group.all_public.size, result.size, "Found all public groups"
  end

end
