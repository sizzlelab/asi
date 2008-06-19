require 'test_helper'

class PersonSpecTest < ActiveSupport::TestCase
  
  def setup
    @valid_person_spec = person_specs(:valid_person_spec)
  end
  
  # def test_max_lengths
  #     PersonSpec::STRING_FIELDS.each do |field|
  #       assert_length :max, @valid_person_spec, field, DB_STRING_MAX_LENGTH
  #     end
  #   end
  
  # Test a saving a blank person_spec.
  # def test_blank
  #   blank = PersonSpec.new(:person_id => @valid_person_spec.person_id)
  #   assert blank.save, blank.errors.full_messages.join("\n")
  # end
  
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
    invalid_genders = ["Eunuch", "Hermaphrodite", "Ann Coulter"]
    invalid_genders.each do |invalid_gender|
      person_spec.gender = invalid_gender
      assert !person_spec.valid?, "#{invalid_gender} shouldn't pass validation, but does."
    end
  end
  
end
