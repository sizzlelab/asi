class Role < ActiveRecord::Base
  belongs_to :person
  belongs_to :client
  
  # TODO add validations for valid role titles
  ADMINISTRATOR = "administrator"
  MODERATOR = "moderator"
  USER = "user"
end
