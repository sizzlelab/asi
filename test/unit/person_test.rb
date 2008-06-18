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

  # Make sure the screen name can't be too short. 
  def test_username_minimum_length 
    person = @valid_person 
    min_length = Person::USERNAME_MIN_LENGTH 

    # Screen name is too short. 
    person.username = "a" * (min_length - 1) 
    assert !person.valid?, "#{person.username} should raise a minimum length error" 
    # Format the error message based on minimum length. 
    correct_error_message = sprintf(@error_messages[:too_short], min_length) 
    assert_equal correct_error_message, person.errors.on(:username) 

    # Screen name is minimum length. 
    person.username = "a" * min_length 
    assert person.valid?, "#{person.username} should be just long enough to pass" 
  end

  # Make sure the screen name can't be too long. 
  def test_username_maximum_length 
    person = @valid_person 
    max_length = Person::USERNAME_MAX_LENGTH 

    # Screen name is too long. 
    person.username = "a" * (max_length + 1) 
    assert !person.valid?, "#{person.username} should raise a maximum length error" 

    # Format the error message based on maximum length 
    correct_error_message = sprintf(@error_messages[:too_long], max_length) 
    assert_equal correct_error_message, person.errors.on(:username) 

    # Screen name is maximum length. 
    person.username = "a" * max_length 
    assert person.valid?, "#{person.username} should be just short enough to pass" 
  end

  # Make sure the password can't be too short. 
  def test_password_minimum_length 
    person = @valid_person 
    min_length = Person::PASSWORD_MIN_LENGTH 

    # Password is too short. 
    person.password = "a" * (min_length - 1) 
    assert !person.valid?, "#{person.password} should raise a minimum length error" 
    # Format the error message based on minimum length. 
    correct_error_message = sprintf(@error_messages[:too_short], min_length) 
    assert_equal correct_error_message, person.errors.on(:password) 

    # Password is just long enough. 
    person.password = "a" * min_length 
    assert person.valid?, "#{person.password} should be just long enough to pass" 
  end 

  # Make sure the password can't be too long. 
  def test_password_maximum_length 
    person = @valid_person 
    max_length = Person::PASSWORD_MAX_LENGTH 

    # Password is too long. 
    person.password = "a" * (max_length + 1) 
    assert !person.valid?, "#{person.password} should raise a maximum length error" 
    # Format the error message based on maximum length. 
    correct_error_message = sprintf(@error_messages[:too_long], max_length) 
    assert_equal correct_error_message, person.errors.on(:password) 

    # Password is maximum length. 
    person.password = "a" * max_length 
    assert person.valid?, "#{person.password} should be just short enough to pass" 
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
