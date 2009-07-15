class Channel < ActiveRecord::Base
#  acts_as_ferret :fields => [:name, :description]

  usesnpguid

  belongs_to :owner, :class_name => "Person"
  belongs_to :creator_app, :class_name => "Client"
  has_many :messages, :dependent => :destroy
  has_many :user_subscriptions
  has_many :group_subscriptions
  has_many :user_subscribers, :through => :user_subscriptions, :source => :person
  has_many :group_subscribers, :through => :group_subscriptions, :source => :group
  
  before_validation_on_create :subscribe_owner
  
  validates_inclusion_of :channel_type, :in => %w( public friend group)
  validates_presence_of :owner_id
  validates_presence_of :creator_app_id
  validates_presence_of :name
  validates_length_of :name, :minimum => 2
  validate :associations_must_exist
  
  private
  
  def subscribe_owner
    if new_record?
      user_subscribers << owner
    end
  end

  def associations_must_exist
    errors.add("Person #{owner.id} does not exist and cannot be channel owner.") if owner && !Person.exists?(owner.id)
    errors.add("Client #{creator_app.id} does not exist.") if creator_app && !Client.exists?(creator_app.id)
    user_subscriber_ids.each do |subscriber|
      errors.add("Person #{subscriber} does not exist and cannot be subscribed to channel.") if !Person.exists?(subscriber)
    end
    group_subscriber_ids.each do |subscriber|
      errors.add("Group #{subscriber} does not exist and cannot be subscribed to channel.") if !Group.exists?(subscriber)
    end
      
  end

end
