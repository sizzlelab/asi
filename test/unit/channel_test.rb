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

require 'test_helper'

class ChannelTest < ActiveSupport::TestCase
  fixtures :channels, :groups

  def test_name
    channel1 = Channel.new(:description => "testikanava" , :owner => people(:test), 
                           :creator_app => clients(:one), :channel_type => "public")
    assert !channel1.valid?
    channel1.name = "f"
    assert !channel1.valid?
    channel1.name = "te"
    assert channel1.valid?
  end

  def test_valid_channel_type
    channel1 = Channel.new( :name => "testi", :description => "testikanava" , :owner => people(:test), 
                            :creator_app => clients(:one), :channel_type => "public")
    assert channel1.valid?
    
    channel2 = Channel.new( :name => "testi", :description => "testikanava" , :owner => people(:test), 
                            :creator_app => clients(:one), :channel_type => "foo" )
    assert !channel2.valid?
  end

  def test_private_channel_type
    channel1 = Channel.new( :name => "testi P", :description => "testikanava PRIVATE" , :owner => people(:test), 
                            :creator_app => clients(:one), :channel_type => "private")
    assert channel1.valid?
  end
  
  def test_hidden_channel
    channel1 = Channel.new( :name => "testi H", :description => "testikanava HIDDEN" , :owner => people(:test), 
                            :creator_app => clients(:one), :hidden => true)
    assert channel1.valid?
  end
  
  def test_delete_channel
    channel1 = Channel.new( :name => "testi", :description => "testikanava" , :owner => people(:test), 
                            :creator_app => clients(:one), :channel_type => "public")
    channel1.save
    channel_id = channel1.id
    channel1.delete
    assert_nil Channel.find_by_id(channel_id)
  end
  
  def test_owner
    channel1 = Channel.new( :name => "testi", :description => "testikanava" , :owner => people(:test), 
                            :creator_app => clients(:one), :channel_type => "public" )
    assert channel1.save
    assert_nothing_raised(ActiveRecord::RecordNotFound) { channel1.user_subscribers.find_by_id(people(:test).id) }
    assert_not_nil channel1.user_subscribers.find_by_id(people(:test).id)
    assert channel1.user_subscribers.length == 1
    
    channel1.owner = nil
    assert !channel1.valid?
    
  end

  def test_creator_app
    channel = Channel.new( :name => "testi", :description => "testikanava" , :owner => people(:test), 
                            :channel_type => "public" )
    assert !channel.valid?
    channel.creator_app = clients(:one)
    assert channel.valid?
    assert channel.save
    
  end

  def test_validates_associations
    channel1 = Channel.new( :name => "testi", :description => "testikanava" , :owner => people(:test), 
                            :creator_app => clients(:one), :channel_type => "public" )
    channel1.save
    assert channel1.user_subscribers << people(:valid_person)
    assert_nothing_raised(ActiveRecord::RecordNotFound) {channel1.user_subscribers.find_by_id(people(:valid_person).id)}

    assert_raise(ActiveRecord::RecordNotFound) {channel1.user_subscriber_ids = %w( foo bar )}
    
    assert channel1.valid?
    
    assert channel1.group_subscribers << groups(:open)
    assert_nothing_raised(ActiveRecord::RecordNotFound) {channel1.group_subscribers.find_by_id(groups(:open))}
    assert_not_nil channel1.group_subscribers.find_by_id(groups(:open))
    
    assert_raise(ActiveRecord::RecordNotFound) {channel1.group_subscriber_ids = %w( foo bar )}
    
    assert channel1.valid?
  end

  def test_group_subscription
    group = Factory(:group, { :title => "Kamppi"})
    channel = Factory(:channel, { :channel_type => "group", :name => "Kamppi" })
    group.save
    channel.save
  end
  
end
