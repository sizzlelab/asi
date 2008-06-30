require 'digest/sha2'

class Person < ActiveRecord::Base
  usesguid
  attr_reader :password #FROM AUTH

  ENCRYPT = Digest::SHA256

  has_one :person_name
  has_one :person_spec
  
  has_many :sessions, :dependent => :destroy

  has_many :connections

  has_many :contacts, 
  :through => :connections,
  :conditions => "status = 'accepted'", 
  :order => :username

  has_many :requested_contacts, 
  :through => :connections, 
  :source => :contact,
  :conditions => "status = 'requested'"#, 
  #:order => :created_at   #commented away for the time being, because caused SQL errors

  has_many :pending_contacts, 
  :through => :connections, 
  :source => :contact,
  :conditions => "status = 'pending'"#, 
  #:order => :created_at   #commented away for the time being, because caused SQL errors

  # Max & min lengths for all fields 
  USERNAME_MIN_LENGTH = 4 
  USERNAME_MAX_LENGTH = 20 
  #PASSWORD_MIN_LENGTH = 4   # removed because now using encryption FROM AUTH
  #PASSWORD_MAX_LENGTH = 40
  USERNAME_RANGE = USERNAME_MIN_LENGTH..USERNAME_MAX_LENGTH 
  #PASSWORD_RANGE = PASSWORD_MIN_LENGTH..PASSWORD_MAX_LENGTH
  EMAIL_MAX_LENGTH = 50 

  # Text box sizes for display in the views 
  USERNAME_SIZE = 20 
  #PASSWORD_SIZE = 10

  validates_uniqueness_of :username, :email
  validates_length_of :username, :within => USERNAME_RANGE
  #validates_length_of :password, :within => PASSWORD_RANGE
  validates_length_of :email, :maximum => EMAIL_MAX_LENGTH
  
  validates_format_of :username, 
                      :with => /^[A-Z0-9_]*$/i, 
                      :message => "must contain only letters, " + 
                      "numbers, and underscores"
  
  # FROM AUTH
  validates_format_of :password, :with => /^([\x20-\x7E]){4,16}$/,
                          :message => "must be 4 to 16 characters",
                          :unless => :password_is_not_being_updated?                    

  validates_format_of :email, 
                      :with => /^[A-Z0-9._%-]+@([A-Z0-9-]+\.)+[A-Z]{2,4}$/i, 
                      :message => "must be a valid email address"
                      
  validates_confirmation_of :password                    

  before_save :scrub_name
  after_save :flush_passwords

  def self.find_by_name_and_password(username, password)
    person = self.find_by_username(username)
    if person and person.encrypted_password == ENCRYPT.hexdigest(password + person.salt)
      return person
    end
  end
 
## FROM AUTH 
  def password=(password)
    @password = password
    unless password_is_not_being_updated?
      self.salt = [Array.new(9){rand(256).chr}.join].pack('m').chomp
      self.encrypted_password = ENCRYPT.hexdigest(password + self.salt)
    end
  end
      
  def to_json(*a)
    person_hash = {
      'id' => id,
      'username' => username,
      'email' => email,
      'name' => person_name
    }
    self.person_spec.attributes.each do |key, value|
      unless PersonSpec::NO_JSON_FIELDS.include?(key)
        if PersonSpec::LOCALIZED_FIELDS.include?(key)
          person_hash.merge!({key, {"displayvalue" => value, "key" => value}})
        else
          person_hash.merge!({key, value})
        end
      end
    end
    return person_hash.to_json(*a)
  end
 
  private
 
  def scrub_name
    self.username.downcase!
  end
 
  def flush_passwords
    @password = @password_confirmation = nil
  end
 
  def password_is_not_being_updated?
    self.id and self.password.blank?
  end
  

  
end
