class PersonSpec < ActiveRecord::Base

  belongs_to :person

  ALL_FIELDS = %w(status_message gender birthdate)
  STRING_FIELDS = %w(status_message)
  # Fields that are not included in json
  NO_JSON_FIELDS = %w(id person_id created_at updated_at)
  # Fields that need to be translated if the language is changed.
  LOCALIZED_FIELDS = %w(gender)
  VALID_GENDERS = ["MALE", "FEMALE"]
  START_YEAR = 1900
  VALID_DATES = DateTime.new(START_YEAR)..DateTime.now

  validates_length_of STRING_FIELDS, :maximum => DB_STRING_MAX_LENGTH

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
    
  def to_json(*a)
    {
      :gender => {"displayname" => self.gender, "key" => self.gender}
    }.to_json(*a)
  end

end
