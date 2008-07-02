class Client < ActiveRecord::Base
  include AuthenticationHelper
  usesguid

  def self.find_by_name_and_password(username, password)
    model = self.find_by_name(username)
    if model and model.encrypted_password == ENCRYPT.hexdigest(password + model.salt)
      return model
    end
  end

end
