class Channel < ActiveRecord::Base

  belongs_to :owner, :class_name => "Person"
  has_many :messages, :dependent => :destroy
  has_many :user_subscribers, :through => :user_subscriptions, :source => :person, :dependent => :destroy
  has_many :group_subscribers, :through => :group_subscriptions, :source => :group, :dependent => :destroy
  
  after_create :subscribe_owner
  
  
  private
  
  def subscribe_owner
    user_subscribers << owner if owner
  end

end
