require 'test_helper'

class AddressTest < ActiveSupport::TestCase

  def setup
    @valid_address = addresses(:one)
  end
  
  def test_max_lengths
    assert_length :max, @valid_address, :street_address, Address::STREET_ADDRESS_MAX_LENGTH
    assert_length :max, @valid_address, :postal_code, Address::POSTAL_CODE_MAX_LENGTH
    assert_length :max, @valid_address, :locality, Address::LOCALITY_MAX_LENGTH
  end
  
end  
