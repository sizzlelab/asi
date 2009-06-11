require 'test_helper'

class GroupTest < ActiveSupport::TestCase

  def test_create_open
    g = Group.new(:title => "testiryhma", :group_type => "open", :creator => people(:valid_person))
    assert(g.valid?, g.errors.full_messages)
    assert(g.save, "Saving failed!")
  end

  def test_create_closed
    g = Group.new(:title => "Closed", :group_type => "closed", :creator => people(:valid_person))
    assert(g.valid?, g.errors.full_messages)
    assert(g.save, "Saving failed!")
  end
  
  def test_add_member_open
    g = Group.create(:title => "testiryhma", :group_type => "open", :creator => people(:valid_person))
    assert(g.valid?, "created group was not valid")

    assert_difference 'g.members.count', 1 do
      people(:friend).request_membership_of(g)
      assert people(:friend).is_member_of?(g), "Joining a group failed."

      assert g.has_member?(people(:friend)), "Person not in a group where he should be"
    end
  end

  def test_add_member_closed
    [ "closed" ].each do |type| 
      g = Group.create(:title => "#{type} test group", :group_type => type, :creator => people(:valid_person))
      assert(g.valid?, g.errors.full_messages.inspect)
      assert(g.save, "Saving failed!")

      assert_no_difference 'g.members.count' do 
        people(:friend).request_membership_of(g)
        assert !people(:friend).is_member_of?(g), "Shouldn't be member."
      end

      assert_difference 'g.members.count', 1 do
        g.admins[0].accept_member(people(:friend), g)

        assert people(:friend).is_member_of?(g)
        assert(g.has_member?(people(:friend)), "Person not in a group where he should be")
      end
    end
  end
  
  def test_granting_admin
    groups(:open).grant_admin_status_to(people(:contact))
    assert people(:contact).is_admin_of?(groups(:open)), "Granting admin status failed"    
  end

  def test_remove_admin
    groups(:open).grant_admin_status_to(people(:contact))
    assert people(:contact).is_admin_of?(groups(:open)), "Granting admin status failed"

    groups(:open).remove_admin_status_from(people(:contact))
    assert ! people(:contact).is_admin_of?(groups(:open)), "Removing admin status failed."
  end

  def test_granting_admin_closed
    people(:contact).request_membership_of(groups(:closed))
    groups(:closed).accept_member(people(:contact))

    groups(:closed).grant_admin_status_to(people(:contact))
    assert people(:contact).is_admin_of?(groups(:closed)), "Granting admin status failed"    
  end
  
  def test_length_boundaries
    assert_length :min, groups(:open), :title, Group::TITLE_MIN_LENGTH
    assert_length :max, groups(:open), :title, Group::TITLE_MAX_LENGTH
    assert_length :max, groups(:open), :description, Group::DESCRIPTION_MAX_LENGTH
  end

  def test_name_uniqueness
    g = Group.new(:title => "testiryhma", :group_type => "open", :creator => people(:valid_person))
    assert g.save

    g2 = Group.new(:title => "testiryhma", :group_type => "open", :creator => people(:valid_person))
    assert ! g2.save, "Allows duplicate group names"

    g3 = Group.new(:title => "Testiryhma", :group_type => "open", :creator => people(:valid_person))
    assert ! g3.save, "Allows case-insensitive duplicate group names"
  end

  def test_invite
    [ groups(:open), groups(:closed) ].each do |group|
      inviter = group.creator
      invitee = people(:friend)
      assert inviter.is_admin_of?(group), "Inviter is not an admin"
      assert ! invitee.is_member_of?(group), "Invitee is a member"

      group.invite(invitee, inviter)

      assert ! invitee.is_member_of?(group), "Invitee is a member too soon"
      assert invitee.invited_groups.include?(group), "Group is not in invitations"
      assert ! invitee.pending_groups.include?(group), "Group is pending"

      invitee.request_membership_of(group)
      assert ! invitee.invited_groups.include?(group), "Group stays in invitations"
      assert invitee.is_member_of?(group)
    end
  end
end
