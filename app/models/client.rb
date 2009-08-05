class Client < ActiveRecord::Base
  include AuthenticationHelper
  usesguid

  has_many :channels

  attr_reader :password

  validates_presence_of [:name, :encrypted_password]
  validates_uniqueness_of :name

  def self.find_by_name_and_password(username, password)
    model = self.find_by_name(username)
    if model and model.encrypted_password == ENCRYPT.hexdigest(password + model.salt)
      return model
    end
  end
end
