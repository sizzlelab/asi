# == Schema Information
#
# Table name: group_search_handles
#
#  id       :integer(4)      not null, primary key
#  group_id :string(255)
#  delta    :boolean(1)      default(TRUE), not null
#

require 'test_helper'

class GroupSearchHandleTest < ActiveSupport::TestCase

  test "search" do
    result = GroupSearchHandle.search "group"

    assert_not_equal 0, result.size, "Found nothing"
    assert_not_equal Group.all_public.size, result.size, "Found all public groups"
  end

end
