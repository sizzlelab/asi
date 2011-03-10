# == Schema Information
#
# Table name: sessions
#
#  id         :integer(4)      not null, primary key
#  person_id  :integer(4)
#  ip_address :string(255)
#  path       :string(255)
#  created_at :datetime
#  updated_at :datetime
#  client_id  :string(255)
#

class Session < ActiveRecord::Base

  EXPIRES_IN = 2.weeks

  attr_accessor :username, :password, :client_name, :client_password, :person_match, :application_login
  belongs_to :person
  belongs_to :client

  before_validation :authenticate_person
  before_validation :authenticate_client

  validates_presence_of :application_login, :message => 'failed',
                        :unless => :session_has_been_associated_with_client?

  before_save :associate_session_to_person
  before_save :associate_session_to_client

  def Session.cleanup
    Session.all(:conditions => [ "updated_at < ?", EXPIRES_IN.ago ]).each do |s|
      s.destroy
    end
  end

  def to_json(*a)
    as_json(*a).to_json(*a)
  end

  def as_json(*a)
    to_hash(*a)
  end

  def to_hash(*a)
    {
      'app_id' => self.client_id,
      'user_id' =>  self.person.andand.guid
    }
  end

  private

  def authenticate_person
    if self.username
      self.person_match = Person.find_by_username_and_password(self.username, self.password) unless session_has_been_associated_with_person?
    end
  end

  def authenticate_client
    self.application_login = Client.find_by_name_and_password(self.client_name, self.client_password) unless session_has_been_associated_with_client?
  end

  def associate_session_to_person
    if self.person_match
      self.person_id ||= self.person_match.id
    end
  end

  def associate_session_to_client
    self.client_id ||= self.application_login.id
  end

  def session_has_been_associated_with_person?
    self.person_id
  end

  def session_has_been_associated_with_client?
    self.client_id
  end

end
