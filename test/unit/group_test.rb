# == Schema Information
#
# Table name: groups
#
#  id          :string(255)     default(""), not null, primary key
#  title       :string(255)
#  creator_id  :integer(4)
#  group_type  :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  description :text
#

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

  def test_unauthorized_invite
    [ groups(:hidden), groups(:closed) ].each do |group|
      inviter = group.members.detect {|p| ! p.is_admin_of?(group) }
      assert inviter, "No non-admin member in #{group.group_type}"
      invitee = people(:friend)
      assert ! inviter.is_admin_of?(group), "Inviter is an admin"
      assert ! invitee.is_member_of?(group), "Invitee is a member"

      group.invite(invitee, inviter)

      assert ! invitee.is_member_of?(group), "Invitee is a member"
      assert ! invitee.invited_groups.include?(group), "Group is in invitations"
      assert ! invitee.pending_groups.include?(group), "Group is pending"

      invitee.request_membership_of(group)
      assert ! invitee.is_member_of?(group)
    end
  end

  def test_change_group_type_to_open

    group = groups(:hidden)
    group.update_attributes(:group_type => "open")
    assert group.group_type == "open", 'Group type should be open"'

    group = groups(:closed)

    people(:contact).request_membership_of(group)
    assert ! group.pending_members.empty?, "Should be one pending member in the group."
    assert ! people(:contact).is_member_of?(group), "Person shouldn't be member."

    group.update_attributes(:group_type => "open")
    assert group.group_type == "open", 'Group type should be open"'

    assert people(:contact).is_member_of?(group), "Person should have been accepted as a member"

  end

  def test_change_group_type_to_hidden
    [ groups(:open), groups(:closed) ].each do |group|
      group.update_attributes(:group_type => "hidden")
      assert group.group_type == "hidden", 'Group type should be hidden'
    end
  end

  def test_change_group_type_to_closed
    [ groups(:open), groups(:hidden) ].each do |group|
      group.update_attributes(:group_type => "closed")
      assert group.group_type == "closed", 'Group type should be closed'
    end
  end

  def test_change_group_type_to_invalid
    [ groups(:open), groups(:hidden), groups(:closed) ].each do |group|
      assert ! group.update_attributes(:group_type => "asoetid")
    end
  end

  def test_hidden_viewing_rules
    group = groups(:hidden)
    assert group.show?(group.members[0]), "Show to member"
    assert ! people(:friend).is_member_of?(group)
    assert ! group.show?(people(:friend)), "Don't show to non-member"
    assert ! Group.all_public.include?(group), "Don't show in public listing"
    group.creator.invite(people(:friend), group)
    assert group.show?(people(:friend)), "Show to invited"
  end

  def test_creator_protection
    group = Group.create(:group_type => "open", :creator => people(:valid_person), :title => "foobaar")
    creator = group.creator

    group.creator = nil
    group.save
    group.reload
    assert_equal creator, group.creator

    group.creator = people(:friend)
    group.save
    group.reload
    assert_equal creator, group.creator
  end
end
