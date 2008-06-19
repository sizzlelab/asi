require 'test_helper'

class PersonTest < ActiveSupport::TestCase

  # Set up "valid" and "invalid" person.
  def setup 
    @error_messages = ActiveRecord::Errors.default_error_messages
    @valid_person = people(:valid_person) 
    @invalid_person = people(:invalid_person) 
  end

  # This person should be valid by construction. 
  def test_person_validity 
    assert people(:valid_person).valid? 
  end

  # This person should be invalid by construction. 
  def test_person_invalidity 
    assert !@invalid_person.valid? 
    attributes = [:username, :password] 
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

  # Check that username is not too long or too short.
  def test_username_length_boundaries
    assert_length :min, @valid_person, :username, Person::USERNAME_MIN_LENGTH
    assert_length :max, @valid_person, :username, Person::USERNAME_MAX_LENGTH
  end

  # Check that password is not too long or too short.
  def test_password_length_boundaries
    assert_length :min, @valid_person, :password, Person::PASSWORD_MIN_LENGTH
    assert_length :max, @valid_person, :password, Person::PASSWORD_MAX_LENGTH
  end

  # Test the validations involving screen name with valid examples.
  def test_username_with_valid_examples 
    person = @valid_person 
    valid_usernames = %w{juho kusti juho_kusti} 
    valid_usernames.each do |username| 
      person.username = username 
      assert person.valid?, "#{username} should pass validation, but doesn't" 
    end 
  end 

  # Test the validations involving screen name with invalid examples.
  def test_username_with_invalid_examples 
    person = @valid_person 
    invalid_usernames = %w{rails/rocks web2.0 javscript:something} 
    invalid_usernames.each do |username| 
      person.username = username
      assert !person.valid?, "#{name} shouldn't pass validation, but does" 
    end 
  end

end
