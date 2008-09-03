require 'test_helper'

class PersonSpecTest < ActiveSupport::TestCase
  
  def setup
    @valid_person_spec = person_specs(:valid_person_spec)
    @blank_person_spec = person_specs(:blank_person_spec)
  end
  
  def test_max_lengths
    PersonSpec::STRING_FIELDS.each do |field|
      assert_length :max, @valid_person_spec, field, DB_STRING_MAX_LENGTH
    end
  end

  # Test saving a blank person_spec.
  def test_blank
    blank = PersonSpec.new(:person_id => @blank_person_spec.person_id)
    assert blank.save, blank.errors.full_messages.join("\n")
  end

  # Test invalid birthdates.
  def test_invalid_birthdates
    person_spec = @valid_person_spec
    invalid_birthdates = [Date.new(PersonSpec::START_YEAR - 1),
      Date.today + 1.year]
    invalid_birthdates.each do |birthdate|
      person_spec.birthdate = birthdate
      assert !person_spec.valid?, "#{birthdate} shouldn't pass validation"
    end
  end  

  # Test for valid genders.
  def test_gender_with_valid_examples
    person_spec = @valid_person_spec
    PersonSpec::VALID_GENDERS.each do |valid_gender|
      person_spec.gender = valid_gender
      assert person_spec.valid?, "#{valid_gender} should pass validation but doesn't." 
    end
  end
  
  # Test invalid genders.
  def test_gender_with_invalid_examples
    person_spec = @valid_person_spec
    invalid_genders = ["Eunuch", "Hermaphrodite"]
    invalid_genders.each do |invalid_gender|
      person_spec.gender = invalid_gender
      assert !person_spec.valid?, "#{invalid_gender} shouldn't pass validation, but does."
    end
  end
  
  def test_should_update_status_message_timestamp
      person_spec = @valid_person_spec
      old_timestamp = person_spec.status_message_changed
      assert_equal( -1 ,old_timestamp.compare_with_coercion(DateTime.now - 1.seconds), "Old timestamp was not old enough for this test." )
      person_spec.status_message = "new test message"
      new_timestamp = person_spec.status_message_changed
      assert_not_equal(old_timestamp, new_timestamp)
      assert_equal( 1 ,new_timestamp.compare_with_coercion(DateTime.now - 1.seconds) , "Timestamp for changed status_message not at current time. Might be just a delay in the processing")
      
  end
  
end
