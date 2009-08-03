require 'digest/sha2'

class Person < ActiveRecord::Base
  include AuthenticationHelper

  include_simple_groups
#  usesguid
  usesnpguid

  attr_reader :password
  attr_protected :roles

  has_one :name, :class_name => "PersonName", :dependent => :destroy
  has_one :address, :as => :owner, :dependent => :destroy
  has_one :location, :dependent => :destroy
  has_one :avatar, :class_name => "Image", :dependent => :destroy
  has_one :pending_validation, :dependent => :destroy

  has_many :roles, :dependent => :destroy
  has_many :sessions, :dependent => :destroy
  has_many :connections, :dependent => :destroy

  has_many :subscriptions, :through => :user_subscriptions, :source => :channel
  has_many :messages

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

  define_index do
    indexes username
    indexes name(:given_name), :as => :given_name
    indexes name(:family_name), :as => :family_name

    has created_at, updated_at
    has name(:id), :as => :name_id

    set_property :enable_star => true
    set_property :min_infix_len => 1
  end

  ALL_FIELDS = %w(status_message birthdate irc_nick msn_nick phone_number description website username name address is_association)
  STRING_FIELDS = %w(status_message irc_nick msn_nick description website)
  # Fields that need to be translated if the language is changed.
  LOCALIZED_FIELDS = %w(gender)
  VALID_GENDERS = ["MALE", "FEMALE"]
  START_YEAR = 1900
  VALID_DATES = DateTime.new(START_YEAR)..DateTime.now

  validates_length_of STRING_FIELDS, :maximum => DB_STRING_MAX_LENGTH, :allow_nil => true, :allow_blank => true
  validates_length_of :phone_number, :maximum => 25, :allow_nil => true, :allow_blank => true

  validates_inclusion_of :gender,
  :in => VALID_GENDERS,
  :allow_nil => true,
  :message => "must be MALE or FEMALE"

  validates_inclusion_of :birthdate,
  :in => VALID_DATES,
  :allow_nil => true,
  :message => "is invalid"

  def status_message=(new_message)
    self[:status_message] = new_message
    self[:status_message_changed] = DateTime.now.utc
  end

  def status_message_changed=(new_date)
    #Status message time stamp cannot be changed by other means than changing the message text
  end

  #added by tchang
  has_many :rules,
           :through => :authorizes
  # has_many :authorizes

  # Max & min lengths for all fields
  PASSWORD_MIN_LENGTH = 4
  PASSWORD_MAX_LENGTH = 16
  USERNAME_MIN_LENGTH = 3
  USERNAME_MAX_LENGTH = 20
  USERNAME_RANGE = USERNAME_MIN_LENGTH..USERNAME_MAX_LENGTH
  EMAIL_MAX_LENGTH = 50

  # Text box sizes for display in the views
  USERNAME_SIZE = 20

  # Constant to present the "accepted" connection in returned JSONs
  ACCEPTED_CONNECTION_STRING = "friend"

  validates_presence_of :username
  #validates_presence_of :password, :unless  => :encrypted_password
  validates_uniqueness_of :username, :email, :case_sensitive => false
  #validates_length_of :username, :within => USERNAME_RANGE
  validates_length_of :password, :minimum => PASSWORD_MIN_LENGTH, :message => "is too short", :unless =>  :password_is_not_being_updated?
  validates_length_of :password, :maximum => PASSWORD_MAX_LENGTH, :message => "is too long", :unless =>  :password_is_not_being_updated?
  #Password length is validated in AuthenticationHelper
  validates_length_of :username, :minimum => USERNAME_MIN_LENGTH, :message => "is too short"
  validates_length_of :username, :maximum => USERNAME_MAX_LENGTH, :message => "is too long"
  validates_length_of :email, :maximum => EMAIL_MAX_LENGTH, :message => "is too long"

  validates_format_of :username,
                      :with => /^[A-Z0-9_]*$/i,
                      :message => "is invalid"

  validates_format_of :password, :with => /^([\x20-\x7E])+$/,
                      :message => "is invalid",
                      :unless => :password_is_not_being_updated?

  validates_format_of :email,
                      :with => /^[A-Z0-9._%-]+@([A-Z0-9-]+\.)+[A-Z]{2,4}$/i,
                      :message => "is invalid"

  before_save :scrub_name
  after_save :flush_passwords


  def update_attributes(hash)
    if hash[:name]
      if name
        name.update_attributes(hash[:name])
      else
        create_name(hash[:name])
      end
    end
    if hash[:address]
      if address
        address.update_attributes(hash[:address])
      else
        create_address(hash[:address])
      end
    end
    if hash[:birthdate] && ! hash[:birthdate].blank?
      #Check the format of the birthday parameter
      begin
        Date.parse(hash[:birthdate])
      rescue ArgumentError => e
        errors.add :birthdate, "is not a valid date or has wrong format, use yyyy-mm-dd"
        return false
      end
    end

    success = super(hash.except(:name, :address))

    if self.name && !self.name.valid?
      success = false
      self.name.errors.each{|attr, msg| errors.add(attr, msg)}
    end
    if self.address && !self.address.valid?
      success = false
      self.address.errors.each{|attr, msg| errors.add(attr, msg)}
    end

    return success
  end

  def self.find_by_username_and_password(username, password)
    model = self.find_by_username(username)
    if model and model.encrypted_password == ENCRYPT.hexdigest(password + model.salt)
      return model
    end
  end

  #creates a hash of person attributes. If connection_person is not nil, adds connection attribute to hash
  # connection_person means the person who is asking to get the hash for current person
  def person_hash(client_id=nil, connection_person=nil, *a)

    person_hash = {
      'id' => guid,
      'avatar' => { :link => { :rel => "self", :href => "/people/#{id}/@avatar" },
                    :status => ( avatar ? "set" : "not_set" ) },
      'status' => { :message => status_message, :changed => status_message_changed },
      :gender => { "displayvalue" => gender, "key" => gender }
    }

    ALL_FIELDS.each do |field|
      person_hash.merge!({ field => self.send(field) })
    end


    #TODO Make more sensible check for the clients that are authorized to get email
    # Currently check if client_id matches to Kassi.
    if connection_person == self || client_id == "acm-TkziGr3z9Tab_ZvnhG"
      person_hash.merge!({'email' => email})
    end

    if connection_person
      person_hash.merge!({'connection' => get_connection_string(connection_person)})
      # if the asker is a friend (or self), include location
      if location && (person_hash['connection'] == ACCEPTED_CONNECTION_STRING || connection_person == self)
        person_hash.merge!({:location => location})
      end
    end

    if !client_id.nil?
      person_hash.merge!({'role' => role_title(client_id)})
    end
    return person_hash
  end

  def to_json(client_id=nil, connection=nil, *a)
    person_hash(client_id, connection).to_json(*a)
  end

# added by tchang
# check if subject_person has access right to model and field
# return: true or false
  def authorize(subject_person=nil, model=nil, field=nil)

    result = false

    if (!model && !field)
      return result
    elsif (model && field)
      # both params model and field are not nil, find action_id
      action = Action.find(:first, :conditions => {'model' => model,'field' => field})
    elsif (model && !field)
      # param model is not nil, while field is nil
      action = Action.find(:first, :condition => ["model = ?", params[model]])
    end

    # find all the rules associated with this person and this action

    rules = Rule.find(:all, :joins => :authorizes, :conditions => {'authorizes.person_id' => id, 'rules.action_id' => action.id})

    rules.each do |rule|
      condition = Condition.find(rule.condition_id)

      if checkCondition(condition, subject_person)
        result = true
      end
    end

    return result
  end

  def checkCondition(condition=nil, subject_person=nil)
    return false
  end

  def moderator?(client)
    return false if client.nil?

    self.roles.each do |role|
      if role.client_id == client.id && role.title == Role::MODERATOR
        return true
      end
    end
    return false #no moderator role found
  end

  def role_title(client_id)
    return nil if client_id.nil?

    self.roles.each do |role|
      if role.client_id == client_id
        return role.title
      end
    end
    return nil # not registered to the client service
  end

  # Create a new avatar image to a person
  def save_avatar?(options)
    if options[:file] && options[:file].content_type.start_with?("image")
      image = Image.new
      if (image.save_to_db?(options, self))
        self.avatar = image
        return true
      end
    end
    return false
  end

  def name_or_username
    if !name.nil?
      name.unstructured
    else
      username
    end
  end

  # Added to conform to Ruby conventions
  def association?
    is_association
  end

  # Methods provided by include_simple_groups:
  # user.groups
  # user.pending_groups
  # user.is_member_of?(group)
  # user.is_mod_of?(group)
  # user.request_membership_of(group)
  # user.pending_and_accepted_groups
  # user.membership(group)
  # user.leave(group)
  # user.become_member_of(group)

  private

  #returns a string representing the connection between the user and the asker
  def get_connection_string(asker)
    type = Connection.type(asker, self)
    if type == "accepted"
      type = ACCEPTED_CONNECTION_STRING
    end
    return type
  end

end
