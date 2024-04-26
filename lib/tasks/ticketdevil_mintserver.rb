require '../../config/environment'
require 'mongoid'
require 'socket'
require 'json'
require_relative 'mint'
require_relative 'ticketdevil_cryptography'
require_relative 'digital_wallet'
require 'logger'




def encode64(string)
  string = string.to_s unless string.is_a?(String)
  Base64.encode64(string)
end

def decode64(string)
  string = string.to_s unless string.is_a?(String)
  Base64.decode64(string)
end

class MintServer
  
  attr_accessor :server
  attr_accessor :client
  attr_accessor :cypto
  attr_accessor :mint
  attr_accessor :mint_wallet
  attr_accessor :exchange
  attr_accessor :cipher
  attr_accessor :decipher
  attr_accessor :logger

  def initialize
    @logger = Logger.new(Logger::DEBUG)
    @mint = TicketDevilMintingBank.new 

    @blockchain = Blockchain.where(:name => "TicketDevil Blockchain").first
    unless @blockchain
      @blockchain = Blockchain.new(:name => "TicketDevil Blockchain")
      @blockchain.save
    end



    bank_wallet = DigitalWallet.where(:wallet_name => 'Bank Wallet').first
    unless bank_wallet
      @bank_wallet = DigitalWallet.new(:wallet_name => 'Bank Wallet')
      @bank_wallet.save
    else
      @bank_wallet = bank_wallet
    end

    @mint_wallet = DigitalWallet.where(:wallet_name => 'Mint Wallet').first
    unless @mint_wallet
      @mint_wallet = DigitalWallet.new(:wallet_name => 'Mint Wallet')
      @mint_wallet.save
    end

    existing_crypto = TicketDevilCryptography.where(:card_name => 'mint wallet crypto card').first
    unless existing_crypto
      @crypto = TicketDevilCryptography.new(:card_name => 'mint wallet crypto card')
      @crypto.crypto_card_carrier = @mint_wallet
      @crypto.save
    else
      @crypto = existing_crypto
      #@crypto.ssobject_load
    end


    @exchange = CentralizedExchange.new
  end


  def run
    loop do
      @mint_wallet.reload
      #coin = @mint.mint(:face_value => 1, :digital_wallet => @mint_wallet)
      #@logger.debug "coin minted, checking balance of mint wallet now"
      #@mint_wallet.reload
      @mint_wallet.check_balance
      #@mint_wallet.debit_coin(coin)
      #@mint_wallet.reload
      #@mint_wallet.check_balance
      @logger.debug "Awaiting wallet identification data from client"
      unparsed_data = @client.gets
      @logger.debug "attempting to parse data"
      @logger.debug unparsed_data
      params = JSON.parse(unparsed_data)
      deciphered_wallet_address = @decipher.decrypt_with_cipher(Base64.decode64(params["receiver_wallet_address"]))
      deciphered_wallet_balance = @decipher.decrypt_with_cipher(Base64.decode64(params["receiver_wallet_balance"]))
      @logger.debug "walletid for receiver is " + deciphered_wallet_address
      @logger.debug "wallet balance for receiver is " + deciphered_wallet_balance
      arandom_secret = (0...16).map { (65 + rand(26)).chr }.join
      signature = @mint_wallet.crypto_card.sign( arandom_secret )
      verified = @mint_wallet.crypto_card.verify(signature, arandom_secret)

      #data = {"wallet_identification" => @mint_wallet.wallet_identification.to_s, "coin_serial_number" => coin.serial_number, "coin_face_value" => coin.face_value.to_s } 
      bank_wallet = DigitalWallet.where(:wallet_identification => deciphered_wallet_address).first
      @logger.debug( 'Bank Wallet is ' )
      @logger.debug bank_wallet.inspect
      block = @blockchain.add_block(
            :sender_wallet_address => @mint_wallet.wallet_identification,
            :sender_wallet_balance => @mint_wallet.balance,
            :receiver_wallet_address => deciphered_wallet_address, #@bank_wallet.wallet_identification,
            :receiver_wallet_balance => deciphered_wallet_balance, #@bank_wallet.balance,
            :sender_public_key => Base64.encode64(@mint_wallet.crypto_card.public_key.to_s),
            :transaction_amount => 1,
            :sender_signature => Base64.encode64(signature),
            :verifiable_data => arandom_secret)
      @logger.debug "Inspecting block"
      @logger.debug block.inspect
      block.save

=begin
      @logger.debug "data is "
      @logger.debug(data)
      ciphered_data = {}
      ciphered_data["wallet_identification"] = encode64(@cipher.encrypt_with_cipher(data["wallet_identification"]))
      ciphered_data["coin_serial_number"] = encode64(@cipher.encrypt_with_cipher(data["coin_serial_number"]))
      ciphered_data["coin_face_value"] = encode64(  @cipher.encrypt_with_cipher(  data["coin_face_value"]  )  )
      @logger.debug( "ciphered data is ")
      @logger.debug( ciphered_data)
      @client.puts(ciphered_data.to_json)
=end
    end
    @client.close
  end

  def secure_connection
    host = 'localhost'
    port = 2000
    @server = TCPServer.open(host, port) # Bind to port 2000
    #ticketdevilbank_crypto = TicketDevilCryptography.new(TicketDevilCryptography::CONFIG)

    @cipher = TicketDevilCipher.new
    @decipher = TicketDevilCipher.new
    @cipher.setup_cipher()
    @decipher.setup_decipher(@cipher.cipher_key, @cipher.cipher_iv)

    random_secret = @cipher.cipher_key #(0...16).map { (65 + rand(26)).chr }.join
    @logger.debug("random secret is " + random_secret.to_s)

    @client = @server.accept
    params = JSON.parse(@client.gets)
    if not params["public_key"].nil?
      @logger.debug("the public key from the client is ")
      @logger.debug( params["public_key"] )
      client_public_key = decode64( params["public_key"] )
      #other_secret = ticketdevil_crypto.encrypt_message(mint_wallet_crypto_card, params[:public_key], "Requesting deposit authorization:", random_secret)
      encrypted_message = @crypto.encrypt_message_with_recipient_public_key(client_public_key, random_secret)
  #    decrypted_message = ticketdevilbank_crypto.decrypt_message_with_private_key(encrypted_message)
  #    encrypted_message = "See if this is even recieved"
      #puts encrypted_message
      encrypted_message_utf8 = encode64(encrypted_message)
      encrypted_cipher_iv = @crypto.encrypt_message_with_recipient_public_key(client_public_key, @cipher.cipher_iv)
      @client.puts({'encrypted_cipher' => encrypted_message_utf8, "encrypted_cipher_iv" => encode64(encrypted_cipher_iv)}.to_json)

      #params = JSON.parse(client.gets)
      #puts "returning from client after decrypt"
      #puts params
      #puts "sending public_key" 
      #puts @crypto.public_key.to_s
      @client.puts({'public_key' => @crypto.public_key.to_s}.to_json)
    end
    params = JSON.parse(@client.gets)
    @logger.debug("params parsed")
    @logger.debug( params)
    client_response = decode64(params["encrypted_secret"])
    decrypted_message = @crypto.decrypt_message_with_private_key(client_response)
    @logger.debug( "decrypted_message" )
    @logger.debug( decrypted_message )
    if decrypted_message == random_secret
      @logger.debug( "VERIFIED" ) 
      return true
    else
      return false
    end
    #client.puts params[:public_key ]
    #raise params.inspect


  end
end

ms = MintServer.new
secure_connection = ms.secure_connection
if secure_connection
  ms.run
end

