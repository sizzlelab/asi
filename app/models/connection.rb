class Connection < ActiveRecord::Base
  belongs_to :person
  # Refer to the second person as "contact".
  belongs_to :contact, :class_name => "Person", :foreign_key => "contact_id"
  validates_presence_of :person_id, :contact_id
  
  # Return true if the people are (possibly pending) contacts.
  def self.exists?(person, contact)
    not find_by_person_id_and_contact_id(person, contact).nil?
  end
  
  # Record a pending connection request.
  def self.request(person, contact)
    unless person == contact or Connection.exists?(person, contact)
      transaction do
        create(:person => person, :contact => contact, :status => 'pending')
        create(:person => contact, :contact => person, :status => 'requested')
      end
    end
  end
  
  # Accept a connection request.
  def self.accept(person, contact)
    transaction do
      accept_one_side(person, contact)
      accept_one_side(contact, person)
    end
  end
  
  # Delete a connection or cancel a pending request.
  def self.breakup(person, contact)
    transaction do
      destroy(find_by_person_id_and_contact_id(person, contact))
      destroy(find_by_person_id_and_contact_id(contact, person))
    end
  end
  
  private
  
  # Update the db with one side of an accepted connection request.
  def self.accept_one_side(person, contact)
    request = find_by_person_id_and_contact_id(person, contact)
    request.status = 'accepted'
    request.save!
  end
  
  def to_s
    return sprintf("%s, %s", person, contact)
  end
  
end
