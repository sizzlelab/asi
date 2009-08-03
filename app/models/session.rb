class Session < ActiveRecord::Base
  attr_accessor :username, :password, :client_name, :client_password, :person_match, :client_match
  belongs_to :person
  belongs_to :client

  before_validation :authenticate_person
  before_validation :authenticate_client

  validates_presence_of :client_match, :message => 'for your clients name and password could not be found',
                                       :unless => :session_has_been_associated_with_client?

  before_save :associate_session_to_person
  before_save :associate_session_to_client

  def to_json(*a)
    session_hash = {
      'app_id' => self.client_id,
      'user_id' =>  self.person.andand.guid

    }
    return session_hash.to_json(*a)
  end

  private

  def authenticate_person
    if self.username
      self.person_match = Person.find_by_username_and_password(self.username, self.password) unless session_has_been_associated_with_person?
    end
  end

  def authenticate_client
    self.client_match = Client.find_by_name_and_password(self.client_name, self.client_password) unless session_has_been_associated_with_client?
  end

  def associate_session_to_person
    if self.person_match
      self.person_id ||= self.person_match.id
    end
  end

  def associate_session_to_client
    self.client_id ||= self.client_match.id
  end

  def session_has_been_associated_with_person?
    self.person_id
  end

  def session_has_been_associated_with_client?
    self.client_id
  end

end
