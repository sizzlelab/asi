# == Schema Information
#
# Table name: addresses
#
#  id             :integer(4)      not null, primary key
#  street_address :string(255)
#  postal_code    :string(255)
#  locality       :string(255)
#  owner_id       :integer(4)
#  owner_type     :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#                                       

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
