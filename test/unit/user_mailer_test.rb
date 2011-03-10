require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  fixtures :people

  def setup
    ActionMailer::Base.deliveries.clear
  end
  
  def test_welcome
    person = people(:valid_person)
    client = clients(:one)
    UserMailer.welcome(person, client).deliver
    
    assert !ActionMailer::Base.deliveries.empty?
    mail = ActionMailer::Base.deliveries.first

    assert_equal([APP_CONFIG.asi_mail_from_address], mail.from)
    assert_equal([person.email], mail.to)
  #  assert_equal("Tervetuloa #{clients(:one).realname || clients(:one).name}-käyttäjäksi! | Welcome to #{clients(:one).realname || clients(:one).name}!", mail.subject)
  end

  def test_registration_confirmation
    person = people(:valid_person)
    mail = UserMailer.registration_confirmation(person, "random_key")
    assert_equal(APP_CONFIG.asi_mail_from_address, mail.from.first)
    assert_equal( "OtaSizzle registration confirmation", mail.subject)
    assert_equal(person.email, mail.to.first)
    
    #TODO tests for the contents too
  end

  def test_password_recovery
    person = people(:valid_person)

    key = CryptoHelper.encrypt("#{person.id}:#{person.salt}")

    UserMailer.recovery(:key => key,
                        :email => person.email,
                        :domain => APP_CONFIG.server_domain).deliver
                                                            
    assert !ActionMailer::Base.deliveries.empty?

    mail = ActionMailer::Base.deliveries.first

    assert_equal([APP_CONFIG.asi_mail_from_address], mail.from)
    assert_equal([person.email], mail.to)
    assert_equal("OtaSizzle password recovery", mail.subject)

    link = "#{APP_CONFIG.server_domain}/people/reset_password?id=#{key}"
    assert_match(link, mail.body)
  end
end
