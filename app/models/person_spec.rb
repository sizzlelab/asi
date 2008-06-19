class PersonSpec < ActiveRecord::Base

  belongs_to :person

  ALL_FIELDS = %w(email status_message gender birthdate)
  STRING_FIELDS = %w(status_message gender)
  EMAIL_MAX_LENGTH = 50
  VALID_GENDERS = ["Male", "Female"]
  START_YEAR = 1900
  VALID_DATES = DateTime.new(START_YEAR)..DateTime.now

  validates_uniqueness_of :email

  validates_length_of :email, :maximum => EMAIL_MAX_LENGTH

  validates_format_of :email, 
  :with => /^[A-Z0-9._%-]+@([A-Z0-9-]+\.)+[A-Z]{2,4}$/i, 
  :message => "must be a valid email address"

  validates_length_of STRING_FIELDS, :maximum => DB_STRING_MAX_LENGTH

  validates_inclusion_of :gender,
  :in => VALID_GENDERS,
  :allow_nil => true,
  :message => "must be male or female"

  validates_inclusion_of :birthdate,
  :in => VALID_DATES,
  :allow_nil => true,
  :message => "is invalid"

end
