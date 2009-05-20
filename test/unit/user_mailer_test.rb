require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  fixtures :people

  def setup
    ActionMailer::Base.deliveries.clear
  end

  def test_registration_confirmation
    person = people(:valid_person)
    mail = UserMailer.create_registration_confirmation(person, "random_key")
    assert_equal(COS_MAIL_FROM_ADRESS, mail.from.first)
    assert_equal( "OtaSizzle registration confirmation", mail.subject)
    assert_equal(person.email, mail.to.first)
    
    #TODO tests for the contents too
  end

  def test_password_recovery
    person = people(:valid_person)

    key = CryptoHelper.encrypt("#{person.id}:#{person.salt}")

    UserMailer.deliver_recovery(:key => key,
                                  :email => person.email,
                                  :domain => SERVER_DOMAIN)
                                                            
    assert !ActionMailer::Base.deliveries.empty?

    mail = ActionMailer::Base.deliveries.first

    assert_equal([COS_MAIL_FROM_ADRESS], mail.from)
    assert_equal([person.email], mail.to)
    assert_equal("OtaSizzle password recovery", mail.subject)

    link = "#{SERVER_DOMAIN}/people/reset_password?id=#{key}"
    assert_match(link, mail.body)
  end
end
