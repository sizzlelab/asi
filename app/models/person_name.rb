class PersonName < ActiveRecord::Base
  acts_as_ferret :fields => [ :unstructured_lowercase ]
  belongs_to :person

  STRING_FIELDS = %w(given_name family_name)

  validates_length_of STRING_FIELDS, 
                      :maximum => DB_STRING_MAX_LENGTH

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
