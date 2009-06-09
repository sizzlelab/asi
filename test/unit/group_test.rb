require 'test_helper'

class GroupTest < ActiveSupport::TestCase

  def test_create_open
    g = Group.new(:title => "testiryhma", :group_type => "open", :created_by => "testperson_id")
    assert(g.valid?, g.errors.full_messages)
    assert(g.save, "Saving failed!")
  end

  def test_create_closed
    g = Group.new(:title => "Closed", :group_type => "closed", :created_by => "testperson_id")
    assert(g.valid?, g.errors.full_messages)
    assert(g.save, "Saving failed!")
  end
  
  def test_add_member_open
    g = Group.create(:title => "testiryhma", :group_type => "open", :created_by => "testperson_id")
    assert(g.valid?, "created group was not valid")
    assert people(:friend).become_member_of(g), "Becoming a member of a group failed"
    assert(people(:friend).is_member_of?(g), "Joining a group failed.")
    
    #add a second member
    people(:not_yet_friend).become_member_of(g)
    assert(people(:not_yet_friend).is_member_of?(g), "Joining a group failed.")
    
    #test asking if member
    assert(g.has_member?(people(:friend)), "Person not in a group where he should be")
    assert(g.has_member?(people(:not_yet_friend)), "Person not in a group where he should be")
    
    #test listing members
    assert(g.members.count == 2, "Person count in group did not match")
  end

  def test_add_member_closed
    [ "closed", "hidden" ].each do |type| 
      g = Group.create(:title => "#{type} test group", :group_type => type, :created_by => "testperson_id")
      assert(g.valid?, g.errors.full_messages.inspect)
      assert(g.save, "Saving failed!")

      #try to add a member without acceptance
      assert !people(:friend).become_member_of(g), "Becoming a member of a group should fail"
      assert !people(:friend).is_member_of?(g), "Shouldn't be member."

      #ask for membership
      people(:friend).request_membership_of(g)
      
      g.reload

      assert people(:friend).become_member_of(g), "Becoming a member of a group failed."
      assert people(:friend).is_member_of?(g)

      #add a second member
      people(:not_yet_friend).request_membership_of(g)

      g.reload

      assert people(:not_yet_friend).become_member_of(g), "Becoming a member of a group failed."
      assert people(:not_yet_friend).is_member_of?(g), "Joining a group failed."

      #test asking if member
      assert(g.has_member?(people(:friend)), "Person not in a group where he should be")
      assert(g.has_member?(people(:not_yet_friend)), "Person not in a group where he should be")

      #test listing members
      assert(g.members.count == 2, "Person count in group did not match")
    end
  end
  
  def test_granting_admin
    groups(:open).grant_admin_status_to(people(:contact))
    assert people(:contact).is_admin_of?(groups(:open)), "Granting admin status failed"    
  end
  
  def test_length_boundaries
    assert_length :min, groups(:open), :title, Group::TITLE_MIN_LENGTH
    assert_length :max, groups(:open), :title, Group::TITLE_MAX_LENGTH
    assert_length :max, groups(:open), :description, Group::DESCRIPTION_MAX_LENGTH
  end

  def test_name_uniqueness
    g = Group.new(:title => "testiryhma", :group_type => "open", :created_by => "testperson_id")
    assert g.save

    g2 = Group.new(:title => "testiryhma", :group_type => "open", :created_by => "testperson_id")
    assert ! g2.save, "Allows duplicate group names"

    g3 = Group.new(:title => "Testiryhma", :group_type => "open", :created_by => "testperson_id")
    assert ! g3.save, "Allows case-insensitive duplicate group names"
  end
  
end
