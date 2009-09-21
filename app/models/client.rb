# == Schema Information
#
# Table name: clients
#
#  id                 :string(255)     default(""), not null, primary key
#  name               :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  encrypted_password :string(255)
#  salt               :string(255)
#

class Client < ActiveRecord::Base
  include AuthenticationHelper
  usesguid

  has_many :channels

  attr_reader :password
  attr_protected :encrypted_password, :salt, :created_at, :updated_at

  validates_presence_of [:name, :encrypted_password]
  validates_uniqueness_of :name

  def self.find_by_name_and_password(username, password)
    model = self.find_by_name(username)
    if model and model.encrypted_password == ENCRYPT.hexdigest(password + model.salt)
      return model
    end
  end

end
