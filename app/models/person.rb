class Person < ActiveRecord::Base
  usesguid
  
  # Max & min lengths for all fields 
  USERNAME_MIN_LENGTH = 4 
  USERNAME_MAX_LENGTH = 20 
  PASSWORD_MIN_LENGTH = 4 
  PASSWORD_MAX_LENGTH = 40
  USERNAME_RANGE = USERNAME_MIN_LENGTH..USERNAME_MAX_LENGTH 
  PASSWORD_RANGE = PASSWORD_MIN_LENGTH..PASSWORD_MAX_LENGTH 

  # Text box sizes for display in the views 
  USERNAME_SIZE = 20 
  PASSWORD_SIZE = 10
  
  validates_uniqueness_of :username
  validates_length_of :username, :within => USERNAME_RANGE
  validates_length_of :password, :within => PASSWORD_RANGE
  validates_format_of :username, 
                      :with => /^[A-Z0-9_]*$/i, 
                      :message => "must contain only letters, " + 
                                  "numbers, and underscores"
  
end
