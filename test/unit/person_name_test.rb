require 'test_helper'

class PersonNameTest < ActiveSupport::TestCase
  
  def setup
    @valid_person_name = person_names(:valid_person_name)
  end
  
  def test_max_lengths
    assert_length :max, @valid_person_name, :given_name, PersonName::GIVEN_NAME_MAX_LENGTH
    assert_length :max, @valid_person_name, :family_name, PersonName::FAMILY_NAME_MAX_LENGTH
  end
  
end
