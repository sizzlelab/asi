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

class Address < ActiveRecord::Base

  belongs_to :owner, :polymorphic => true

  STREET_ADDRESS_MAX_LENGTH = 50
  POSTAL_CODE_MAX_LENGTH = 8
  LOCALITY_MAX_LENGTH = 50

#  validates_presence_of :owner_id, :owner_type

  validates_length_of :street_address, :allow_nil => true, :maximum => STREET_ADDRESS_MAX_LENGTH
  validates_length_of :postal_code, :allow_nil => true, :maximum => POSTAL_CODE_MAX_LENGTH
  validates_length_of :locality, :allow_nil => true, :maximum => LOCALITY_MAX_LENGTH

  def to_json(*a)
    as_json(*a).to_json(*a)
  end

  def as_json(*a)
    to_hash(*a)
  end

  def to_hash(*a)  
    {
      :unstructured => self.unstructured,
      :street_address => self.street_address,
      :postal_code => self.postal_code,
      :locality => self.locality
    }
  end

  def unstructured
    if street_address && street_address != "" && ((postal_code && postal_code != "") || (locality && locality != ""))
      "#{street_address}, #{postal_code} #{locality}"
    else
      "#{street_address} #{postal_code} #{locality}"
    end
  end

end
