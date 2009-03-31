require 'test_helper'

class GroupTest < ActiveSupport::TestCase

  def test_create
    g = Group.new(:title => "testiryhma")
    assert(g.valid?, "Group not valid!")
    assert(g.save, "Saving failed!")
  end
  
  def test_add_member
    g = Group.create(:title => "testiryhma")
    people(:friend).become_member_of(g) 
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
    
  
end