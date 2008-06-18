class Connection < ActiveRecord::Base
  belongs_to :person
  # Refer the second person as "connection of person".
  belongs_to :contact, :class_name => "Person", :foreign_key => "contact_id"
  
  validates_presence_of :person_id, :contact_id
end
