class Role < ActiveRecord::Base
  belongs_to :person
  belongs_to :client
  
  # TODO add validations for valid role titles
  ADMINISTRATOR = "administrator"
  MODERATOR = "moderator"
  USER = "user"
  
  def self.find_by_client_id(client_id)
    Role.find(:all, :conditions => "client_id = '#{client_id}'")
  end
  
  def self.find_by_user_id(user_id)
    Role.find(:all, :conditions => "person_id = '#{user_id}'")
  end
end
