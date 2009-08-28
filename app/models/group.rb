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

# -*- coding: utf-8 -*-
class Group < ActiveRecord::Base
  usesguid

  has_many :memberships, :dependent => :destroy
  has_many :members, :through => :memberships, :source => :person, :conditions => 'accepted_at IS NOT NULL'
  has_many :pending_members, :through => :memberships, :source => :person, :conditions => 'accepted_at IS NULL'
  has_many :admins, :through => :memberships, :source => :person, :conditions => ['admin_role = ?', true]
  has_many :invited_members, :through => :memberships, :source => :person, :conditions => 'inviter_id IS NOT NULL'

  has_many :subscriptions, :through => :group_subscriptions, :source => :channel

  belongs_to :creator, :foreign_key => "creator_id", :class_name => "Person"

  has_one :group_search_handle, :dependent => :destroy
  after_create :create_search_handle

  attr_readonly :creator_id

  VALID_GROUP_TYPES =  %w(open closed hidden) #personal (to be implemented)
  TITLE_MIN_LENGTH = 2
  TITLE_MAX_LENGTH = 70
  DESCRIPTION_MAX_LENGTH = 5000

  validates_inclusion_of :group_type,
                         :in => VALID_GROUP_TYPES,
                         :allow_nil => false,
                         :message => "must currently be 'open', 'closed', 'hidden' " #or 'personal'"

  validates_length_of :title, :within => TITLE_MIN_LENGTH..TITLE_MAX_LENGTH
  validates_length_of :description, :allow_nil => true, :allow_blank => true, :maximum => DESCRIPTION_MAX_LENGTH, :message => "is too long"
  validates_presence_of :creator

  validates_uniqueness_of :title, :case_sensitive => false

  after_create :make_creator_member

  def make_creator_member
    accept_member(creator)
    grant_admin_status_to(creator)
  end

  def Group.all_public
    Group.all(:conditions => ["group_type = 'open' OR group_type = 'closed'"])
  end

  def Group.search(*a)
    GroupSearchHandle.search(*a)
  end

  def public?
    group_type == "open" || group_type == "closed"
  end

  def membership(person)
    Membership.find(:first, :conditions => ['group_id = ? AND person_id = ?', self.id, person.id])
  end

  def request_membership(person)
    accept_member(person) and return if invited_members.include?(person)
    members << person
    accept_member(person) if auto_accept_members?
  end

  def invite(person, inviter)
    return false if invited_members.include?(person)
    if auto_accept_members? or inviter.is_admin_of?(self)
      members << person
      person.membership(self).update_attribute("inviter", inviter)
      return true
    end
    return false
  end

  def accept_member(person)
    members << person unless membership(person)
    self.membership(person).update_attribute(:accepted_at, Time.now)
  end

  def pending_and_accepted_members
    self.pending_members + self.members
  end

  def kick(person)
    self.membership(person).destroy if person.is_member_of?(self)

    if members.count == 0
      destroy
    elsif admins.empty?
      restore_admin_rights
    end
  end

  def has_member?(person)
    self.members.include?(person)
  end

  def grant_admin_status_to(person)
    person.membership(self).update_attribute("admin_role", true) if person.is_member_of?(self)
  end

  def remove_admin_status_from(person)
    person.membership(self).update_attribute("admin_role", false) if person.is_member_of?(self)
  end

  def show?(person, client=nil)
    return true if group_type == "open" || group_type == "closed"
    return false if not person
    return true if person == creator
    return true if person.is_member_of?(self)
    return true if invited_members.include?(person)
    false
  end

  def to_json(asking_person=nil, *a)
    group_hash = get_group_hash(asking_person)
    return group_hash.to_json
  end

  def to_hash(user, client)
    get_group_hash(user)
  end

  def get_group_hash(asking_person=nil)
    group_hash = {
      'id' => id,
      'title' => title,
      'description' => description,
      'group_type' => group_type,
      'created_at' => created_at,
      'created_by' => creator.andand.guid,
      'number_of_members' => members.count
      }

    if asking_person
      group_hash.merge!({'is_member' => (has_member?(asking_person))})
      group_hash.merge!({'is_admin' => asking_person.is_admin_of?(self)}) if has_member?(asking_person)
    end
    return group_hash
  end

  #Overwritten update_attributes method that updates pending members if
  #group type is changed to open
  def update_attributes(attributes)
    if attributes[:group_type] == 'open'
      pending_members.each do |pending|
        accept_member pending
      end
    end
    super
  end

  def restore_admin_rights
    oldest_membership = memberships.sort_by{ |membership| membership.created_at }.first
    grant_admin_status_to(oldest_membership.person)
  end

  private

  def auto_accept_members?
    self.group_type == 'open'
  end

  def create_search_handle
    GroupSearchHandle.create(:group => self)
  end


  # def json_with_members
  #   #TODO add info of members
  #   hash = self.to_json
  #   #puts hash.inspect
  #   return hash
  # end
end
