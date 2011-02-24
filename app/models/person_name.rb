# == Schema Information
#
# Table name: person_names
#
#  id          :integer(4)      not null, primary key
#  given_name  :string(255)     default("")
#  family_name :string(255)     default("")
#  created_at  :datetime
#  updated_at  :datetime
#  person_id   :integer(4)
#

class PersonName < ActiveRecord::Base

  belongs_to :person

  attr_protected :created_at, :updated_at

  GIVEN_NAME_MAX_LENGTH = 30
  FAMILY_NAME_MAX_LENGTH = 30

  validates_length_of :given_name, :maximum => GIVEN_NAME_MAX_LENGTH
  validates_length_of :family_name, :maximum => FAMILY_NAME_MAX_LENGTH


  def to_json(*a)
    {
      :unstructured => self.unstructured,
      :given_name => self.given_name,
      :family_name => self.family_name
    }.to_json(*a)
  end

  def unstructured_lowercase
    return self.unstructured.downcase
  end

  def unstructured
    "#{given_name} #{family_name}"
  end
end
