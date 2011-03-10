# == Schema Information
#
# Table name: person_specs
#
#  id                     :integer(4)      not null, primary key
#  person_id              :integer(4)
#  status_message         :string(255)     default("")
#  birthdate              :date
#  gender                 :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  status_message_changed :datetime
#  irc_nick               :string(255)
#  msn_nick               :string(255)
#  phone_number           :string(255)
#  description            :string(255)
#  website                :string(255)
#

class PersonSpec < ActiveRecord::Base

  belongs_to :person

  ALL_FIELDS = %w(status_message gender birthdate irc_nick msn_nick phone_number description website)
  STRING_FIELDS = %w(status_message irc_nick msn_nick description website)
  # Fields that are not included in json
  NO_JSON_FIELDS = %w(id person_id created_at updated_at)
  # Fields that need to be translated if the language is changed.
  LOCALIZED_FIELDS = %w(gender)
  VALID_GENDERS = ["MALE", "FEMALE"]
  START_YEAR = 1900
  VALID_DATES = DateTime.new(START_YEAR)..DateTime.now

  validates_length_of STRING_FIELDS, :maximum => Asi::Application.config.DB_STRING_MAX_LENGTH, :allow_nil => true, :allow_blank => true
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

  def to_json(*a)
    as_json(*a).to_json(*a)
  end

  def as_json(*a)
    to_hash(*a)
  end

  def to_hash(*a)  
    {
      :gender => {"displayname" => self.gender, "key" => self.gender}
    }
  end
end
