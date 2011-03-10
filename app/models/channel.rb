# == Schema Information
#
# Table name: channels
#
#  id             :integer(4)      not null, primary key
#  name           :string(255)
#  description    :string(255)
#  owner_id       :integer(4)
#  channel_type   :string(255)
#  hidden         :boolean(1)      default(FALSE), not null
#  created_at     :datetime
#  updated_at     :datetime
#  creator_app_id :string(255)
#  guid           :string(255)
#  delta          :boolean(1)      default(TRUE), not null
#

class Channel < ActiveRecord::Base

  usesnpguid

  belongs_to :owner, :class_name => "Person"
  belongs_to :creator_app, :class_name => "Client"
  has_many :messages, :dependent => :destroy
  has_many :user_subscriptions, :dependent => :destroy
  has_many :group_subscriptions, :dependent => :destroy
  has_many :user_subscribers, :through => :user_subscriptions, :source => :person
  has_many :group_subscribers, :through => :group_subscriptions, :source => :group

  attr_accessible :name, :description, :channel_type, :hidden, :owner, :creator_app
  attr_readonly :channel_type, :creator_app, :hidden

  scope :not_hidden, :conditions => { :hidden => 0 }

  after_create :subscribe
  before_validation(:on => :create){ set_default_type }

  validates_inclusion_of :channel_type, :in => %w( public friend group private), :message => "must be public, friend group or private."
  validates_presence_of :owner_id
  validates_presence_of :creator_app_id
  validates_presence_of :name
  validates_length_of :name, :minimum => 2
  validate :associations_must_exist
  validate :validate_group_count

  define_index do
    indexes :name, :sortable => true
    indexes :description

    indexes messages(:body), :as => :posts
    indexes messages(:title), :as => :msg_title, :sortable => true

    has :guid
    has :created_at
    has :updated_at

    where "hidden = 0"

    set_property :field_weights => { 'name' => 10,
                                     'description' => 5,
                                     'posts' => 2,
                                     'msg_title' => 1 }
    set_property :enable_star => true
    set_property :min_infix_len => 1
    set_property :delta => true
  end

  def show?(user, client=nil)
    can_read?(user)
  end

  def can_read?(user)
    if channel_type == "public"
      return true
    end
    if user
      if channel_type == "friend"
        if self.owner == user
          return true
        else
          return user.contacts.include?(owner)
        end
      end
      if channel_type == "group"
        group_subscribers.each do |subscription|
          return user.groups.include?(subscription)
        end
      end
      if channel_type == "private"
        return user_subscribers.include?(user)
      end
    end
    return false
  end

  def to_json(*a)
    as_json(*a).to_json(*a)
  end

  def as_json(*a)
    to_hash(*a)
  end

  # user and client parameters are required for sphinx
  def to_hash(user=nil, client=nil)
    hash = {
      :id => guid,
      :name => name,
      :description => description,
      :owner_id => owner.guid,
      :owner_name => owner.name_or_username,
      :created_at => created_at,
      :updated_at => updated_at,
      :channel_type => channel_type,
      :hidden => hidden,
      :message_count => self.messages.size
    }

    if messages.size > 0
      poster = self.messages.first.poster
      if poster
        hash.merge!({ :updated_by => { :link => poster.to_link, :name => poster.display_name }})
      end
    else
      hash.merge!({ :updated_by => { :link => owner.to_link, :name => owner.display_name }})
    end

    hash
  end

  def touch
    group_subscribers.each do |group|
      group.touch
    end
    self.updated_at = Time.now
    self.save
  end
  
  private

  def validate_group_count
    if self.channel_type == "group"
      if self.group_subscribers.size > 1
        errors.add("of type 'group' can have only one group subscriber.")
      end
    end
  end

  def set_default_type
    if !self.channel_type
      self.channel_type = "public"
    end
  end

  def subscribe
    user_subscribers << owner rescue ActiveRecord::RecordInvalid
  end

  def associations_must_exist
    errors.add("Person #{owner.id} does not exist and cannot be channel owner.") if owner && !Person.exists?(owner.id)
    errors.add("Client #{creator_app.id} does not exist.") if creator_app && !Client.exists?(creator_app.id)
#    user_subscriber_ids.each do |subscriber|
#      errors.add("Person #{subscriber} does not exist and cannot be subscribed to channel.") if !Person.exists?(subscriber)
#    end
#    group_subscriber_ids.each do |subscriber|
#      errors.add("Group #{subscriber} does not exist and cannot be subscribed to channel.") if !Group.exists?(subscriber)
#    end

  end

end
