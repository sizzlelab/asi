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
