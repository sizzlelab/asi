require 'test_helper'

class PersonTest < ActiveSupport::TestCase

  def setup 
    @error_messages = ActiveRecord::Errors.default_error_messages
    @valid_person = people(:valid_person) 
    @invalid_person = people(:invalid_person) 
  end
  
  def test_uniqueness_of_username
    person_repeat = Person.new(:username => @valid_person.username)
    assert !person_repeat.valid?
    assert_equal @error_messages[:taken], person_repeat.errors.on(:username)
  end
    
end
