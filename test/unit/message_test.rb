# == Schema Information
#
# Table name: messages
#
#  id           :integer(4)      not null, primary key
#  title        :string(255)
#  content_type :string(255)
#  body         :text
#  poster_id    :integer(4)
#  channel_id   :integer(4)
#  created_at   :datetime
#  updated_at   :datetime
#  reference_to :integer(4)
#  attachment   :string(255)
#  guid         :string(255)
#  delta        :boolean(1)      default(TRUE), not null
#

require 'test_helper'

class MessageTest < ActiveSupport::TestCase

  def test_creation_and_delete
    message = Message.new( :title => "testiviesti", :body => "Tämä on viesti\nSiinä on rivejä.",
                           :poster => people(:test), :channel => channels(:julkikanava),
                           :attachment => "www.example.com", :content_type => "text/url")
    assert message.valid?
    assert message.save
    message_id = message.id
    assert message.delete
    assert_nil Message.find_by_id(message_id)
    
    message2 = Message.new(:title => "testiviesti", :body => "Tämä on viesti\nSiinä on rivejä.",
                           :poster => people(:test),
                           :attachment => "www.example.com", :content_type => "text/url")
    assert !message2.valid?

    message3 = Message.new( :title => "testiviesti", :body => "Tämä on viesti\nSiinä on rivejä.",
                           :channel => channels(:julkikanava),
                           :attachment => "www.example.com", :content_type => "text/url")
    assert !message3.valid?

  end
  
end
