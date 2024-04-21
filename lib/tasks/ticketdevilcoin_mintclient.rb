require '../../config/environment'
require 'mongoid'
require 'socket'
require 'json'
require_relative 'ticketdevil_cryptography'
require_relative 'digital_wallet'
require_relative 'centralized_exchange'
require 'logger'


def encode64(string)
  string = string.to_s unless string.is_a?(String)
  Base64.encode64(string)
end

def decode64(string)
  string = string.to_s unless string.is_a?(String)
  Base64.decode64(string)
end

class MintClientBank

  attr_accessor :bank_client
  attr_accessor :bank_crypto
  attr_accessor :bank_wallet
  attr_accessor :cipher
  attr_accessor :cipher_key
  attr_accessor :ciphera_iv
  attr_accessor :logger

  def initialize

    @logger = Logger.new(Logger::DEBUG)


    bank_wallet = DigitalWallet.where(:wallet_name => 'Bank Wallet').first
    unless bank_wallet
      @bank_wallet = DigitalWallet.new(:wallet_name => 'Bank Wallet')
      @bank_wallet.save
    else
      @bank_wallet = bank_wallet
    end

    existing_bank_crypto = TicketDevilCryptography.where(:card_name => "Mint Bank Wallet Crypto Card").first
    unless existing_bank_crypto
      @bank_crypto = TicketDevilCryptography.new(:card_name => "Mint Bank Wallet Crypto Card")
      @bank_crypto.crypto_card_carrier = @bank_wallet
      @bank_crypto.save
    else
      @bank_crypto = existing_bank_crypto
      #@bank_crypto.ssobject_load
    end

    @exchange = CentralizedExchange.new
  end

  #so one way to transfer funds would be to have a secret inside the coin that is
  #sent to the CentralExchange which authorizes any transfers - and stores the wallet
  #its currently cointained in
  #so the central exchange authorizes and stores the new wallet info for that coin
  #maybe a central exchange should be allowed to lock coins that way nothing can happen to it
  #in the middle of transfer
  def run
    cipher_done = false
    loop do
      response = @bank_client.gets
      @logger.debug("response is ")
      @logger.debug( response )
      params = JSON.parse(response) unless response.nil?
      data = {}

      @decipher = TicketDevilCipher.new unless cipher_done
      
      @decipher.setup_decipher(@cipher_key, @cipher_iv) unless cipher_done

      @logger.debug "pre-cipher response params is"
      @logger.debug params.inspect

      data["wallet_identification"] = @decipher.decrypt_with_cipher(decode64(params["wallet_identification"]))
      data["coin_serial_number"] = @decipher.decrypt_with_cipher(decode64(params["coin_serial_number"]))
      data["coin_face_value"] = @decipher.decrypt_with_cipher(decode64(params["coin_face_value"]))
      @logger.debug "post-cipher data is "
      @logger.debug data
      @logger.debug "starting transfer"
      mint_wallet = DigitalWallet.where(:wallet_identification => data["wallet_identification"]).first
      @logger.debug mint_wallet.inspect
      CentralizedExchange.transfer(mint_wallet, @bank_wallet, data["coin_serial_number"], data["coin_face_value"])
      cipher_done = true
    end
    @bank_client.close
  end

  def secure_connection
    host = 'localhost'
    port = 2000
    @bank_client = TCPSocket.open(host, port)
    request = { 'public_key' => @bank_crypto.public_key }.to_json
    @logger.debug "requesting "
    @logger.debug request.inspect
    @logger.debug "bank crypto object"
    @logger.debug @bank_crypto.inspect
    @bank_client.puts(request)
    response = @bank_client.gets
    params = JSON.parse(response) unless response.nil?
    @logger.debug "params is "
    @logger.debug params
    #unless not params.nil?
    @logger.debug 'in block'
    encrypted_message = params["encrypted_cipher"]
    encrypted_message = decode64(encrypted_message)

    encrypted_iv = params["encrypted_cipher_iv"]

    decrypted_message = @bank_crypto.decrypt_message_with_private_key(encrypted_message)
    @cipher_key = decrypted_message
    decrypted_iv = @bank_crypto.decrypt_message_with_private_key(decode64(encrypted_iv))
    @cipher_iv = decrypted_iv

    @logger.debug "\n\n"
    @logger.debug "decrypted mesage IS "
    @logger.debug decrypted_message

      #here is where we need to get the public key and encrypt it with the decrypted_message
    #end
    response = @bank_client.gets
    params = JSON.parse(response) unless response.nil?
    @logger.debug "params is "
    @logger.debug params
    server_public_key = decode64(params["public_key"])
    @logger.debug "server_public_key is"
    @logger.debug server_public_key
    encrypted_secret = @bank_crypto.encrypt_message_with_recipient_public_key(server_public_key, decrypted_message)
    @bank_client.puts( {"encrypted_secret" => encode64(encrypted_secret) }.to_json )
    @logger.debug "sent encrypted secret"
    return true


  end
end

mcb = MintClientBank.new
if mcb.secure_connection
  mcb.logger.debug "calling run"
  mcb.run
end

