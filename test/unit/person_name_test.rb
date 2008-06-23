require 'test_helper'

class PersonNameTest < ActiveSupport::TestCase
  
  def setup
    @valid_person_name = person_names(:valid_person_name)
  end
  
  def test_max_lengths
    PersonName::STRING_FIELDS.each do |field|
      assert_length :max, @valid_person_name, field, DB_STRING_MAX_LENGTH
    end
  end
  
end
