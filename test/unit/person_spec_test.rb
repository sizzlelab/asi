# == Schema Information
#
# Table name: person_specs
#
#  id                     :integer(4)      not null, primary key
#  person_id              :integer(4)
#  status_message         :string(255)     default("")
#  birthdate              :date
#  gender                 :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  status_message_changed :datetime
#  irc_nick               :string(255)
#  msn_nick               :string(255)
#  phone_number           :string(255)
#  description            :string(255)
#  website                :string(255)
#

require 'test_helper'

class PersonSpecTest < ActiveSupport::TestCase

  def setup
    @valid_person = people(:valid_person)
    @blank_person = people(:blank_person)
  end

  def test_max_lengths
    Person::STRING_FIELDS.each do |field|
      assert_length :max, @valid_person, field, Asi::Application.config.DB_STRING_MAX_LENGTH\
    end
  end

  def test_phone_number_length
    person = @valid_person
    person.phone_number = "more than 25 digits in this string"
    assert !person.valid?
  end

  # Test invalid birthdates.
  def test_invalid_birthdates
    person = @valid_person
    invalid_birthdates = [Date.new(Person::START_YEAR - 1),
      Date.today + 1.year]
    invalid_birthdates.each do |birthdate|
      person.birthdate = birthdate
      assert !person.valid?, "#{birthdate} shouldn't pass validation"
    end
  end

  # Test for valid genders.
  def test_gender_with_valid_examples
    person = @valid_person
    Person::VALID_GENDERS.each do |valid_gender|
      person.gender = valid_gender
      assert person.valid?, "#{valid_gender} should pass validation but doesn't."
    end
  end

  # Test invalid genders.
  def test_gender_with_invalid_examples
    person = @valid_person
    invalid_genders = ["Eunuch", "Hermaphrodite"]
    invalid_genders.each do |invalid_gender|
      person.gender = invalid_gender
      assert !person.valid?, "#{invalid_gender} shouldn't pass validation, but does."
    end
  end

  def test_should_update_status_message_timestamp
      person = @valid_person
      old_timestamp = person.status_message_changed
      assert_equal( -1 ,old_timestamp.compare_with_coercion(DateTime.now - 1.seconds), "Old timestamp was not old enough for this test." )
      person.status_message = "new test message"
      new_timestamp = person.status_message_changed
      assert_not_equal(old_timestamp, new_timestamp)
      assert_equal( 1 ,new_timestamp.compare_with_coercion(DateTime.now - 1.seconds) , "Timestamp for changed status_message not at current time. Might be just a delay in the processing")

  end

end
