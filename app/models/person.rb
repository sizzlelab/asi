class Person < ActiveRecord::Base
  usesguid
  validates_uniqueness_of :username
  validates_length_of     :username, :within => 4..20
  validates_format_of     :username, 
                          :with => /^[A-Z0-9_]*$/i, 
                          :message => "must contain only letters, numbers and underscores"
  validates_length_of     :password, :within => 4..40   
end
