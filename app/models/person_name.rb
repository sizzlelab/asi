class PersonName < ActiveRecord::Base
  belongs_to :person
  
  STRING_FIELDS = %w(given_name, family_name)
  
  validates_length_of STRING_FIELDS, 
                      :maximum => DB_STRING_MAX_LENGTH
  
end
