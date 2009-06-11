class Role < ActiveRecord::Base
  belongs_to :person
  belongs_to :client

  validates_presence_of :title, :client_id, :person_id

  ADMINISTRATOR = "administrator"
  MODERATOR = "moderator"
  USER = "user"

  validates_inclusion_of :title, :in => [ADMINISTRATOR, MODERATOR, USER], 
                                 :message => "Role title %s is not valid."
  
  def self.find_by_user_and_client_id(user_id, client_id)
    Role.find(:all, :conditions => { :person_id => user_id, :client_id => client_id })
  end
  
  def self.find_by_client_id(client_id)
    Role.find(:all, :conditions => "client_id = '#{client_id}'")
  end
  
  def self.find_by_user_id(user_id)
    Role.find(:all, :conditions => "person_id = '#{user_id}'")
  end

end
