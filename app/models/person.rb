require 'digest/sha2'

class Person < ActiveRecord::Base
  include AuthenticationHelper

  usesguid

  attr_reader :password

  has_one :name, :class_name => "PersonName"
  has_one :person_spec
  has_one :location
  
  has_many :sessions, :dependent => :destroy

  has_many :connections

  has_many :contacts, 
  :through => :connections,
  :conditions => "status = 'accepted'", 
  :order => :username

  has_many :requested_contacts, 
  :through => :connections, 
  :source => :contact,
  :conditions => "status = 'requested'" 

  has_many :pending_contacts, 
  :through => :connections, 
  :source => :contact,
  :conditions => "status = 'pending'"

  # Max & min lengths for all fields 
  USERNAME_MIN_LENGTH = 4 
  USERNAME_MAX_LENGTH = 20 
  USERNAME_RANGE = USERNAME_MIN_LENGTH..USERNAME_MAX_LENGTH 
  EMAIL_MAX_LENGTH = 50 

  # Text box sizes for display in the views 
  USERNAME_SIZE = 20 

  validates_uniqueness_of :username, :email
  validates_length_of :username, :within => USERNAME_RANGE
  validates_length_of :email, :maximum => EMAIL_MAX_LENGTH
  
  validates_format_of :username, 
                      :with => /^[A-Z0-9_]*$/i, 
                      :message => "must contain only letters, " + 
                      "numbers, and underscores"
  
  validates_format_of :password, :with => /^([\x20-\x7E]){4,16}$/,
                          :message => "must be 4 to 16 characters",
                          :unless => :password_is_not_being_updated?                    

  validates_format_of :email, 
                      :with => /^[A-Z0-9._%-]+@([A-Z0-9-]+\.)+[A-Z]{2,4}$/i, 
                      :message => "must be a valid email address"               

  before_save :scrub_name
  after_save :flush_passwords

  def update_attributes(hash)
    if name
      name.update_attributes(hash[:name])
    else
      create_name(hash[:name])
    end
    super(hash.except(:name))
  end

  def self.find_by_username_and_password(username, password)
    model = self.find_by_username(username)
    if model and model.encrypted_password == ENCRYPT.hexdigest(password + model.salt)
      return model
    end
  end

  # Bring a simple setter to each attribute of PersonSpec in order to simplify the interface
  PersonSpec.new.attributes.each do |key, value|
    unless Person.new.respond_to?("#{key}=") || key.end_with?("_id")
      Person.class_eval "def #{key}=(value); "+
          "if ! person_spec; "+
            "create_person_spec; "+
          "end; "+
          "person_spec.#{key}=value; "+
        "end;"
    end
  end

  def to_json(*a)
    person_hash = {
      'id' => id,
      'username' => username,
      'email' => email,
      'name' => name
    }
    if self.person_spec
      self.person_spec.attributes.each do |key, value|
        unless PersonSpec::NO_JSON_FIELDS.include?(key)
          if PersonSpec::LOCALIZED_FIELDS.include?(key)
            person_hash.merge!({key, {"displayvalue" => value, "key" => value}})
          else
            person_hash.merge!({key, value})
          end
        end
      end
    end
    return person_hash.to_json(*a)
  end

  def self.find_with_ferret(query, options={ :limit => :all }, search_options={})
    if query && query.length > 0
      query = "*#{query.downcase}*"
    else
      query = ""
    end
    names = PersonName.find_with_ferret(query, options, search_options)
    return names.collect{|name| name.person}.compact
  end
end
