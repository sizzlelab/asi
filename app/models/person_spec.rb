class PersonSpec < ActiveRecord::Base

  belongs_to :person

  ALL_FIELDS = %w(email status_message gender birthdate)
  STRING_FIELDS = %w(status_message)
  VALID_GENDERS = ["Male", "Female"]
  START_YEAR = 1900
  VALID_DATES = DateTime.new(START_YEAR)..DateTime.now

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
