class Group < ActiveRecord::Base
  usesguid

  has_many :memberships
  has_many :members, :through => :memberships, :source => :person, :conditions => 'accepted_at IS NOT NULL'
  has_many :pending_members, :through => :memberships, :source => :person, :conditions => 'accepted_at IS NULL'
  has_many :mods, :through => :memberships, :source => :person, :conditions => ['admin_role = ?', true]

  VALID_GROUP_TYPES =  %w(open) #closed hidden personal (to be implemented)
  TITLE_MIN_LENGTH = 2
  TITLE_MAX_LENGTH = 70
  DESCRIPTION_MAX_LENGTH = 400

  validates_inclusion_of :group_type,
                         :in => VALID_GROUP_TYPES,
                         :allow_nil => false,
                         :message => "must currently be 'open'" #", 'closed', 'hidden' or 'personal'"
                         
  validates_length_of :title, :within => 2..70
  validates_length_of :description, :allow_nil => true, :allow_blank => true, :maximum => DESCRIPTION_MAX_LENGTH, :message => "is too long"                       
  
  def membership(person)
    Membership.find(:first, :conditions => ['group_id = ? AND person_id = ?', self.id, person.id])
  end

  def accept_member(person)
    #puts "accepting #{person.username}"
    #puts self.membership(person).inspect
    if self.membership(person)
      self.membership(person).update_attribute(:accepted_at, Time.now)
      return true
    else
      return false
    end
    
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
    if !person.nil?
      self.members.push(person) unless self.pending_and_accepted_members.include?(person)
    end 
    #puts "Members lisäyksen JÄLKEEN: #{self.members.inspect}"
  end
  
  def grant_admin_status_to(person)
    person.membership(self).update_attribute("admin_role", true) if person.is_member_of?(self)
  end
  
  def json_with_members
    #TODO add info of members
    hash = self.to_json
    #puts hash.inspect
    return hash
  end
end
