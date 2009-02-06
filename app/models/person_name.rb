class PersonName < ActiveRecord::Base
  acts_as_ferret :fields => [ :unstructured_lowercase ]
  belongs_to :person

  GIVEN_NAME_MIN_LENGTH = 1
  GIVEN_NAME_MAX_LENGTH = 30
  FAMILY_NAME_MIN_LENGTH = 1
  FAMILY_NAME_MAX_LENGTH = 30

  validates_length_of :given_name, :minimum => GIVEN_NAME_MIN_LENGTH
  validates_length_of :given_name, :maximum => GIVEN_NAME_MAX_LENGTH
  validates_length_of :family_name, :minimum => FAMILY_NAME_MIN_LENGTH
  validates_length_of :family_name, :maximum => FAMILY_NAME_MAX_LENGTH

  def to_json(*a)
    {
      :unstructured => self.unstructured,
      :given_name => self.given_name,
      :family_name => self.family_name
    }.to_json(*a)
  end                

  def unstructured_lowercase
    return self.unstructured.downcase
  end
  
  def unstructured
    "#{given_name} #{family_name}"
  end
end
