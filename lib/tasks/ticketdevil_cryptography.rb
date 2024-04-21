
require 'mongoid'
require 'base64'
require 'openssl'


class TicketDevilCryptography

  include Mongoid::Document
  include Mongoid::Timestamps

  CONFIG = {
    :key_length  => 4096,
    :digest_func => OpenSSL::Digest::SHA256.new
  }

  belongs_to :crypto_card_carrier, :polymorphic => true, :index => true


  field :private_key #this is a base64.encode64 key stored in mongo
  field :public_key  #this is also a base64.encode64 stored in mongo
  field :card_name

  attr_accessor :config
  attr_accessor :ss_private_key
  attr_accessor :ss_public_key
  attr_accessor :logger

  after_find :init_logger
  before_create :init_logger
  before_create :pre_init

  def pre_init
    self.card_name = 'default card' if self.card_name.nil?
    keypair = OpenSSL::PKey::RSA.new(CONFIG[:key_length])
    self.private_key = Base64.encode64(keypair.private_to_pem)
    self.public_key  = Base64.encode64(keypair.public_to_pem) #OpenSSL::PKey::RSA.new(@keypair.public_key.to_der)
  end

  def init_logger
    @logger = Logger.new(Logger::DEBUG)
    @logger.debug("initialized logger in digital wallet")
  end

=begin
  def make_party(name)
    # create a public/private key pair for this party

    # extract the public key from the pair

    { :keypair => @pair, :pubkey => @public_key, :name => @card_name }

  end
=end

  def encrypt_message_with_recipient_public_key(recipient_public_key, message)
    recipient_public_key  = OpenSSL::PKey::RSA.new(recipient_public_key)
    encrypted_message = recipient_public_key.public_encrypt(message)
    #encrypted_secret = to_party[:pubkey].public_encrypt(secret)
    return encrypted_message
  end

  def encrypt_message_with_public_key(message)
    if self.public_key.is_a?(String)
      self.public_key = OpenSSL::PKey::RSA.new( Base64.decode64( self.public_key) )
    end
    encrypted_message = self.public_key.public_encrypt(message)
    return encrypted_message
    #encrypted_secret = to_party[:pubkey].public_encrypt(secret)
  end

  def decrypt_message_with_private_key(encrypted_message)
    if self.private_key.is_a?(String)
      self.private_key = OpenSSL::PKey::RSA.new( Base64.decode64( self.private_key) )
    end
    decrypted_message = self.private_key.private_decrypt(encrypted_message)
    return decrypted_message
  end

  def process_message(conf, from_party, to_party, message, secret)

    # using the sender's private key, generate a signature for the message
    signature = from_party[:keypair].sign(conf[:digest_func], message)

    # messages are encrypted (by the sender) using the recipient's public key
    encrypted_message = to_party[:pubkey].public_encrypt(message)
    encrypted_secret = to_party[:pubkey].public_encrypt(secret)

    #this is where the code needs to break, and the encrypted data sent tot he client

    # messages are decrypted (by the recipient) using their private key
    decrypted = to_party[:keypair].private_decrypt(encrypted_message)
    decrypted_secret = to_party[:keypair].private_decrypt(encrypted_secret)

    @logger.debug "Signature:"
    @logger.debug Base64.encode64(signature)

    @logger.debug '\n'
    @logger.debug "Encrypted:"
    @logger.debug Base64.encode64(encrypted_message)

    @logger.debug '\n'
    @logger.debug "From: #{from_party[:card_name]}"
    @logger.debug "To  : #{to_party[:card_name]}"

    @logger.debug 
    @logger.debug "Decrypted:"
    @logger.debug decrypted

    if from_party[:pubkey].verify(CONFIG[:digest_func], signature, decrypted)
      @logger.debug "Verified!"
    end
    return decrypted_secret

  end
  def sign(message)
    if self.private_key.is_a?(String)
      self.private_key = OpenSSL::PKey::RSA.new( Base64.decode64( self.private_key) )
    end
    signature = self.private_key.sign(CONFIG[:digest_func], message)
    return signature
  end

  def verify(signature, decrypted_data)
    if self.public_key.is_a?(String)
      self.public_key = OpenSSL::PKey::RSA.new( Base64.decode64( self.public_key) )
    end
    result = self.public_key.verify(CONFIG[:digest_func], signature, decrypted_data)
    return result
  end
end

class TicketDevilCipher

  attr_accessor :cipher
  attr_accessor :cipher_key
  attr_accessor :cipher_iv
  attr_accessor :decipher

  def initialize
  end

  def setup_cipher
    @cipher = OpenSSL::Cipher::AES.new(128, :CBC)
    @cipher.encrypt
    @cipher_key = @cipher.random_key
    @cipher_iv = @cipher.random_iv
  end

  def encrypt_with_cipher(data)
    encrypted = @cipher.update(data) + @cipher.final
    return encode64(encrypted)
  end

  def setup_decipher(key, iv)
    @decipher = OpenSSL::Cipher::AES.new(128, :CBC)
    @decipher.decrypt
    @decipher.key = key
    @decipher.iv = iv
  end

  def decrypt_with_cipher(encrypted_data)
    data_to_decrypt = decode64(encrypted_data)
    plain = @decipher.update( data_to_decrypt ) + @decipher.final
    return plain
  end
end


