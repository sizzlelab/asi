require 'digest/sha2'

module AuthenticationHelper

  ENCRYPT = Digest::SHA256

  def password=(password)
    @password = password
    
    if errors[:password].empty?
        self.salt = [Array.new(9){rand(256).chr}.join].pack('m').chomp
        self.encrypted_password = ENCRYPT.hexdigest(password + self.salt)
    end
  end
 
  def scrub_name
    self.username.downcase!
  end
 
  def flush_passwords
    @password = @password_confirmation = nil
  end
 
  #The purpose of this method is probably that it checks if password is being updated or not
  # ie. if there already is an encrypted password and we need no checkin for the clear text password
  def password_is_not_being_updated?
    self.id and self.password.nil?
  end

end
