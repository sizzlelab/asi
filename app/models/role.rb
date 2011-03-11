# == Schema Information
#
# Table name: roles
#
#  id                      :integer(4)      not null, primary key
#  person_id               :integer(4)
#  client_id               :string(255)
#  title                   :string(255)
#  created_at              :datetime
#  updated_at              :datetime
#  terms_version           :string(255)
#  location_security_token :string(255)
#

class Role < ActiveRecord::Base
  belongs_to :person
  belongs_to :client
  
  validates_presence_of :title, :client_id, :person_id

  ADMINISTRATOR = "administrator"
  MODERATOR = "moderator"
  USER = "user"
  
  validates_uniqueness_of :location_security_token, :allow_nil => true

  validates_inclusion_of :title, :in => [ADMINISTRATOR, MODERATOR, USER], 
  :message => "Role title %{value} is not valid."
  
  def self.find_all_by_person_and_client_id(person_id, client_id)
    Role.where(:person_id => person_id, :client_id => client_id)
  end
  
  def self.find_by_person_and_client_id(person_id, client_id)
    Role.where(:person_id => person_id, :client_id => client_id).first
  end

  
 # Creates location security token
  def location_security_token
    #Creates new location security token if it is missing
    self.update_attributes(:location_security_token => UUID.timestamp_create.to_s) unless self[:location_security_token]
    
    return self[:location_security_token]
  end
  
  def location_security_token=(value)
    self[:location_security_token] ||= value
  end

  def find_by_location_security_token_and_client_id(token, client_id)
    role = Role.find_by_location_security_token(token)
    return role if role.client_id == client_id
  end
end
