require 'test_helper'
require 'json'

class PersonTest < ActiveSupport::TestCase

  def setup 
    @error_messages = ActiveRecord::Errors.default_error_messages
    @valid_person = people(:valid_person) 
    @invalid_person = people(:invalid_person)
    @valid_person_spec = person_specs(:valid_person_spec) 
    @valid_person_name = person_names(:valid_person_name)
    @valid_avatar = images(:jpg)
  end

  # This person should be valid by construction. 
  def test_person_validity 
    assert people(:valid_person).valid? 
  end

  # This person should be invalid by construction. 
  # def test_person_invalidity 
  #    assert !@invalid_person.valid? 
  #    attributes = [:username, :encrypted_password] 
  #    attributes.each do |attribute| 
  #      assert @invalid_person.errors.invalid?(attribute) 
  #    end 
  #  end
  # FROM AUTH should be remade because new costraints for password...

  # Check uniqueness of username.
  def test_uniqueness_of_username
    person_repeat = Person.new(:username => @valid_person.username)
    assert !person_repeat.valid?
    assert_equal @error_messages[:taken], person_repeat.errors.on(:username)
  end
  
  # Check uniqueness of email.
  def test_uniqueness_of_email
    person_repeat = Person.new(:email => @valid_person.email)
    assert !person_repeat.valid?
    assert_equal @error_messages[:taken], person_repeat.errors.on(:email)
  end

  # Check that username is not too long or too short.
  def test_username_length_boundaries
    assert_length :min, @valid_person, :username, Person::USERNAME_MIN_LENGTH
    assert_length :max, @valid_person, :username, Person::USERNAME_MAX_LENGTH
  end

  # Check that password is not too long or too short.
  # def test_password_length_boundaries
  #   assert_length :min, @valid_person, :password, Person::PASSWORD_MIN_LENGTH
  #   assert_length :max, @valid_person, :password, Person::PASSWORD_MAX_LENGTH
  # end
  # FROM AUTH

  # Test the validations involving username with valid examples.
  def test_username_with_valid_examples 
    person = @valid_person 
    valid_usernames = %w{juho kusti juho_kusti} 
    valid_usernames.each do |username| 
      person.username = username 
      assert person.valid?, "#{username} should pass validation, but doesn't" 
    end 
  end 

  # Test the validations involving username with invalid examples.
  def test_username_with_invalid_examples 
    person = @valid_person 
    invalid_usernames = %w{rails/rocks web2.0 javscript:something} 
    invalid_usernames.each do |username| 
      person.username = username
      assert !person.valid?, "#{name} shouldn't pass validation, but does" 
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
      assert_equal "is invalid", person.errors.on(:email) 
    end
  end

  def test_to_json
    person = @valid_person
    person.person_spec = @valid_person_spec
    person.name = @valid_person_name
    avatar = @valid_avatar
    assert avatar.valid_file?
    avatar.full_image_size = '"240x300"'
    avatar.thumbnail_size = '"50x64"'
    assert avatar.convert
    person.avatar = @valid_avatar
    json = JSON.parse(person.to_json)
    assert_not_nil json["id"]
    assert_not_nil json["username"]
    assert_not_nil json["email"]
    assert_not_nil json["name"]
    assert_not_nil json["name"]["unstructured"]
    assert_nil json["password"]
    PersonSpec::ALL_FIELDS.each do |value|
      assert_not_nil json[value]
    end  
  end

  def test_name_update
    p = Person.new
    p.create_name(:given_name => "Mikko")
    p.name.update_attributes({ :family_name => "Virtanen" })
    assert_equal "Mikko", p.name.given_name
  end

end
