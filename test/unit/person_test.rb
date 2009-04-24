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
    @valid_person_spec = person_specs(:valid_person_spec) 
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
       assert @invalid_person.errors.invalid?(attribute) 
     end 
   end

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
      assert_equal "is invalid", person.errors.on(:email)
    end
  end

  def test_to_json
    person = @valid_person
    person.person_spec = @valid_person_spec
    person.name = @valid_person_name
    avatar = @valid_avatar
    avatar.person_id = person.id
    assert avatar.valid_file?("image/jpeg", "testfile.jpg")
    assert avatar.convert
    person.avatar = @valid_avatar
    json = JSON.parse(person.to_json(nil,person))
    assert_not_nil json["id"]
    assert_not_nil json["username"]
    assert_not_nil json["email"]
    assert_not_nil json["name"]
    assert_not_nil json["name"]["unstructured"]
    assert_nil json["password"]
    spec_fields = PersonSpec::ALL_FIELDS
    #special check for status, because response json is different from model structure
    spec_fields.delete("status_message")
    assert_not_nil json["status"]["message"]
    spec_fields.delete("status_message_changed")
    assert_not_nil json["status"]["changed"]
    assert_not_nil(json["location"])
    assert(json["location"]["latitude"]<=90)
    assert(json["location"]["latitude"]>=-90)
    
    spec_fields.each do |value|
        assert_not_nil json[value] , "#{value} was nil."
    end  
  end

  def test_name_update
    p = Person.new
    p.create_name(:given_name => "Mikko")
    p.name.update_attributes({ :family_name => "Virtanen" })
    assert_equal "Mikko", p.name.given_name
  end

end
