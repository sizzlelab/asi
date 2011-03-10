require 'test_helper'

class MembershipTest < ActiveSupport::TestCase

  def test_status
    group = Factory(:group, :group_type => "closed")
    person = Factory(:person)

    assert_equal "active", group.membership(group.creator).status

    group.creator.invite(person, group)

    assert_equal "invited", group.membership(person).status

    person.join(group)
    assert_equal "active", group.membership(person).status

    person.leave(group)
    person.request_membership_of(group)
    assert_equal "requested", group.membership(person).status
  end

end
