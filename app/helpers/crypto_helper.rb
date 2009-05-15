# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'openssl'
require 'digest/sha2'

module CryptoHelper
    KEY = "asoenthuSTNOHUSNET2344==+++324234+naosetuaoeu=23=324//a3245bHEHUoeuh.rcdyfR+.p1ahbe"

    def self.encrypt(plain_text)
      crypto = start(:encrypt)

      cipher_text = crypto.update(plain_text)
      cipher_text << crypto.final

      cipher_hex = cipher_text.unpack("H*")

      return cipher_hex
    end

    def self.decrypt(cipher_hex)
      crypto = start(:decrypt)

      cipher_text = cipher_hex.gsub(/(..)/){|h| h.hex.chr}
      plain_text = crypto.update(cipher_text)
      
      plain_text << crypto.final

      return plain_text
    end

    def self.start(mode)
      crypto = OpenSSL::Cipher::Cipher.new('aes-256-ecb').send(mode)
      crypto.key = Digest::SHA256.hexdigest(KEY)

      return crypto
    end
end
