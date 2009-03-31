class Group < ActiveRecord::Base
  usesguid

  has_many :memberships
  has_many :members, :through => :memberships, :source => :person, :conditions => 'accepted_at IS NOT NULL'
  has_many :pending_members, :through => :memberships, :source => :person, :conditions => 'accepted_at IS NULL'
  has_many :mods, :through => :memberships, :source => :person, :conditions => ['admin_role = ?', true]
  
  #TODO add validations
  # validation for type open/closed/hidden/personal
  
  def membership(person)
    Membership.find(:first, :conditions => ['group_id = ? AND person_id = ?', self.id, person.id])
  end
  
  def accept_member(person)
    #puts "accepting #{person.username}"
    #puts self.membership(person).inspect
    self.membership(person).update_attribute(:accepted_at, Time.now)
    #puts self.membership(person).inspect

  end
  
  def pending_and_accepted_members
    self.pending_members + self.members
  end
  
  def kick(person)
    self.membership(person).destroy if person.is_member_of?(self)
  end
  
  # def mods_online
  #   self.mods.find(:all, :conditions => ['people.updated_at > ?', 50.seconds.ago])
  # end
  # 
  # def members_online
  #   self.members.find(:all, :conditions => ['people.updated_at > ?', 70.seconds.ago])
  # end
  # 
  # def members_offline
  #   self.members - self.members_online
  # end
  
  def has_member?(person)
    self.members.include?(person)
  end
  
  def add_member(person)
    #puts "Members ENNEN lisäystä: #{self.members.inspect}"
    self.members.push(person) unless self.pending_and_accepted_members.include?(person)
    #puts "Members lisäyksen JÄLKEEN: #{self.members.inspect}"
  end
end
