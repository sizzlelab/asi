class Address < ActiveRecord::Base
  
  belongs_to :owner, :polymorphic => true
  
  STREET_ADDRESS_MAX_LENGTH = 50
  POSTAL_CODE_MAX_LENGTH = 8
  LOCALITY_MAX_LENGTH = 50

  validates_presence_of :owner_id, :owner_type
  
  validates_length_of :street_address, :allow_nil => true, :maximum => STREET_ADDRESS_MAX_LENGTH
  validates_length_of :postal_code, :allow_nil => true, :maximum => POSTAL_CODE_MAX_LENGTH
  validates_length_of :locality, :allow_nil => true, :maximum => LOCALITY_MAX_LENGTH

  def to_json(*a)
    {
      :unstructured => self.unstructured,
      :street_address => self.street_address,
      :postal_code => self.postal_code,
      :locality => self.locality
    }.to_json(*a)
  end                
  
  def unstructured
    if street_address && street_address != "" && ((postal_code && postal_code != "") || (locality && locality != ""))
      "#{street_address}, #{postal_code} #{locality}"
    else
      "#{street_address} #{postal_code} #{locality}"
    end    
  end

end
