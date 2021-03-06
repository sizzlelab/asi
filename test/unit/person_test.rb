# == Schema Information
#
# Table name: people
#
#  id                     :integer(4)      not null, primary key
#  username               :string(255)
#  encrypted_password     :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  email                  :string(255)
#  salt                   :string(255)
#  consent                :string(255)
#  coin_amount            :integer(4)      default(0), not null
#  is_association         :boolean(1)
#  status_message         :string(255)
#  status_message_changed :datetime
#  gender                 :string(255)
#  irc_nick               :string(255)
#  msn_nick               :string(255)
#  phone_number           :string(255)
#  description            :text
#  website                :string(255)
#  birthdate              :date
#  guid                   :string(255)
#  delta                  :boolean(1)      default(TRUE), not null
#

require 'test_helper'
require 'json'

class PersonTest < ActiveSupport::TestCase

  def setup
    begin  #this is done to have compatibility with both Rails 2.1 and 2.2
      @error_messages = I18n.translate('activerecord.errors.messages')
    rescue Exception => e
      @error_messages = ActiveRecord::Errors.default_error_messages
    end
    @valid_person = people(:valid_person)
    @invalid_person = people(:invalid_person)
    @valid_person_name = person_names(:valid_person_name)
    @valid_avatar = images(:jpg)
  end

  # This person should be valid by construction.
  def test_person_validity
    assert people(:valid_person).valid?
  end

  # This person should be invalid by construction.
  def test_person_invalidity
     assert !@invalid_person.valid?
     attributes = [:username, :email]
     attributes.each do |attribute|
       assert @invalid_person.errors[attribute].any?
     end
   end

  # Check uniqueness of username, must be case insesitive.
  def test_uniqueness_of_username
    person_repeat = Person.new(:username => @valid_person.username.upcase)
    assert !person_repeat.valid?
    assert_equal @error_messages[:taken], person_repeat.errors[:username][0], "Test must be case sensitive."
  end

  # Check uniqueness of email.
  def test_uniqueness_of_email
    person_repeat = Person.new(:email => @valid_person.email.upcase)
    assert !person_repeat.valid?
    assert_equal @error_messages[:taken], person_repeat.errors[:email][0], "Test must be case sensitive."
  end

  # Check that username is not too long or too short.
  def test_username_length_boundaries
    assert_length :min, @valid_person, :username, Person::USERNAME_MIN_LENGTH
    assert_length :max, @valid_person, :username, Person::USERNAME_MAX_LENGTH
  end

  # This is not in use because password lenght is validated only on create and update, not on model level, as normal
  # Password constraints are tested in people_controller_test (func)

  # Check that password is not too long or too short.
  # def test_password_length_boundaries
  #   just_created_person = Person.new(:email => "valid@example.com", :username => "passwdtester", :password => "firstProperValue") #password length is only checked if encrypted password is not already set
  #   assert_length :min, just_created_person, :password, Person::PASSWORD_MIN_LENGTH
  #   assert_length :max, just_created_person, :password, Person::PASSWORD_MAX_LENGTH
  # end

  # Test the validations involving username with valid examples.
  def test_username_with_valid_examples
    person = @valid_person
    valid_usernames = %w{juho kusti juho_kusti enu}
    valid_usernames.each do |username|
      person.username = username
      assert person.valid?, "#{username} should pass validation, but doesn't"
    end
  end

  # Test the validations involving username with invalid examples.
  def test_username_with_invalid_examples
    person = @valid_person
    invalid_usernames = %w{rails/rocks web2.0 javscript:something ME}
    invalid_usernames.each do |username|
      person.username = username
      assert !person.valid?, "#{username} shouldn't pass validation, but does"
    end
  end

  # Test the email validator against valid email addresses.
  def test_email_with_valid_examples
    person = @valid_person
    valid_endings = %w{com org net edu es jp info}
    valid_emails = valid_endings.collect do |ending|
      "foo.bar_1-9@baz-quux0.example.#{ending}"
    end
    valid_emails.each do |email|
      person.email = email
      assert person.valid?, "#{email} must be a valid email address"
    end
  end

  # Test the email validator against invalid email addresses.
  def test_email_with_invalid_examples
    person = @valid_person
    invalid_emails = %w{foobar@example.c @example.com f@com foo@bar..com
                        foobar@example.infod foobar.example.com
                        foo,@example.com foo@ex(ample.com foo@example,com}
    invalid_emails.each do |email|
      person.email = email
      assert !person.valid?, "#{email} tests as valid but shouldn't be"
      assert_equal "is invalid", person.errors[:email][0]
    end
  end

  def test_to_json
    person = @valid_person
    person.name = @valid_person_name
    avatar = @valid_avatar
    avatar.person = @valid_person

    person.rules.each { |r| r.destroy }
    person.reload
    
    raw_json = person.to_json(person, person.roles[0].client)

    assert_equal raw_json.gsub("gender", ""), raw_json.sub("gender", ""), "Duplicate gender key"

    json = JSON.parse(raw_json)

    assert_not_nil json["id"]
    assert_not_nil json["username"]
    assert_not_nil json["email"]
    assert_not_nil json["name"]
    assert_not_nil json["name"]["unstructured"]
    assert_not_nil json["name"]["given_name"]
    assert_not_nil json["name"]["family_name"]
    assert_nil json["password"]

    #special check for status, because response json is different from model structure
    assert_not_nil json["connection"]

    spec_fields = PersonSpec::ALL_FIELDS
    spec_fields.delete("status_message")

    assert_not_nil json["status"]["message"]
    spec_fields.delete("status_message_changed")
    assert_not_nil json["status"]["changed"]

    assert_not_nil(json["location"])
    assert_not_nil(json["location"]["label"])
    assert(json["location"]["latitude"]<=90)
    assert(json["location"]["latitude"]>=-90)

    assert_not_nil json["role"], "Role is missing"

    assert_not_nil json["updated_at"], "updated_at"

    spec_fields.each do |value|
        assert_not_nil json[value] , "#{value} was nil."
    end
  end

  def test_privacy
    person = @valid_person
    json = JSON.parse(person.to_json)
    assert_nil json["email"], "Email is not private"
    assert_nil json["location"], "Location is not private"
  end


  def test_name_update
    p = Person.new
    p.create_name(:given_name => "Mikko")
    p.name.update_attributes({ :family_name => "Virtanen" })
    assert_equal "Mikko", p.name.given_name
  end

  def test_association_info
    p = @valid_person
    p.is_association = true
    p.description = "Otaniemi Underground Fishing Academy"
    p.website = "http://oufa.tky.fi"
    assert p.save
  end

  def test_association_json
    p = @valid_person
    p.is_association = true
    p.description = "Otaniemi Underground Fishing Academy"
    p.website = "http://oufa.tky.fi"
    json = JSON.parse(p.to_json)

    assert_equal true, json["is_association"], "Association status"
    assert_equal "Otaniemi Underground Fishing Academy", json["description"], "Description"
    assert_equal "http://oufa.tky.fi", json["website"], "Website"
  end

  def test_self_connection
    p = @valid_person
    json = JSON.parse(p.to_json(p, clients(:one)))
    assert_equal "you", json["connection"]
  end

  def test_friend_connection
    p = @valid_person
    json = JSON.parse(p.to_json(p.contacts[0], clients(:one)))
    assert_equal "friend", json["connection"]
  end

  def test_kassi_email_kludge
    p = @valid_person
    json = JSON.parse(p.to_json)
    assert_nil json["email"]

    json = JSON.parse(p.to_json(nil, clients(:kassi)))
    assert_equal p.email, json["email"]
  end

  def test_description_length
    p = @valid_person
    p.description = (1..1000).map.join
    assert p.save
    p.reload
    assert_equal (1..1000).map.join, p.description
  end

  def test_password_validation
    p = Person.create(:username => "foo", :email => "bar@c.com", :password => "")
    assert_equal 1, p.errors.full_messages.size

    p = Person.create(:username => "foo", :email => "bar@c.com", :password => "\x19\x19\x19\x19\x19\x19\x19\x19")
    assert_equal 1, p.errors.full_messages.size
  end


end
