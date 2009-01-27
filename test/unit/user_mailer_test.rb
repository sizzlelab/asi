require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  fixtures :people
  
  
  def test_registration_confirmation
    person = people(:valid_person)
    mail = UserMailer.create_registration_confirmation(person, "random_key")
    assert_equal(COS_MAIL_FROM_ADRESS, mail.from.first)
    assert_equal( "OtaSizzle registration confirmation", mail.subject)
    assert_equal(person.email, mail.to.first)
    
    #TODO tests for the contents too
  end
end
