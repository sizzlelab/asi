class Role < ActiveRecord::Base
  belongs_to :person
  belongs_to :client
  
  validates_presence_of :title, :client_id, :person_id

  ADMINISTRATOR = "administrator"
  MODERATOR = "moderator"
  USER = "user"
  
  validates_uniqueness_of :location_security_token, :allow_nil => true

  validates_inclusion_of :title, :in => [ADMINISTRATOR, MODERATOR, USER], 
  :message => "Role title {{value}} is not valid."
  
  def self.find_by_user_and_client_id(user_id, client_id)
    Role.find(:all, :conditions => { :person_id => user_id, :client_id => client_id })
  end
  
  def self.find_by_client_id(client_id)
    Role.find(:all, :conditions => "client_id = '#{client_id}'")
  end
  
  def self.find_by_user_id(user_id)
    Role.find(:all, :conditions => "person_id = '#{user_id}'")
  end
  
 # Creates location security token
  def create_location_security_token
    #Creates new location security token if it is missing
    self.update_attributes(:location_security_token => UUID.timestamp_create.to_s) unless self.location_security_token
  end
  
  def location_security_token=(value)
    self[:location_security_token] ||= value
  end

end
