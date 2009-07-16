class PersonName < ActiveRecord::Base

  belongs_to :person

  define_index do
    indexes given_name
    indexes family_name

    set_property :enable_star => true
    set_property :min_infix_len => 1
  end

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
