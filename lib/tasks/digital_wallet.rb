require 'mongoid'
require 'securerandom'
require_relative 'ledger'
require_relative 'mint'
require 'logger'

#how do we verify a wallet isn't just creating as many coins as it wants?
#the bank ledger should perhaps own and issue the wallet even if someone else is using it.

class DigitalWallet
  include Mongoid::Document
  include Mongoid::Timestamps

  has_one :crypto_card, :as => :crypto_card_carrier, :class_name => "TicketDevilCryptography" #crypto card needs to have its own private key, and password
  has_one :ledger #each wallet should have its own ledger for credits and debits

  has_many :coins, :class_name => 'TicketDevilMintCoin'

  field :wallet_name
  field :balance
  field :wallet_identification

  #should add a field to consider whether a wallet is "open" or not

  index( {wallet_identification: 1}, { unique: true })
  index({ wallet_name: 1 })

  after_create :do_crypto_card, :do_ledger

  # it would be fine to have this
  after_find :init_logger
  before_create :init_logger
  before_create :pre_init

  attr_accessor :logger


  def pre_init
    if self.wallet_name.nil?
      self.wallet_name = 'Default Wallet'
    end
    if self.balance.nil?
      self.balance = 0
    end
    if self.wallet_identification.nil?
      self.wallet_identification = SecureRandom.uuid
    end
  end

  def init_logger
    @logger = Logger.new(Logger::DEBUG)
    @logger.debug("initialized logger in digital wallet")
  end

  def do_ledger
    self.ledger = Ledger.new(:ledger_name => self.wallet_name + " Ledger")
    self.ledger.digital_wallet = self
    self.ledger.save
  end

  def do_crypto_card
    #return if TicketDevilCryptography.where(
    @crypto_card = TicketDevilCryptography.new
    @crypto_card.crypto_card_carrier = self
    @crypto_card.save
  end

  #need to ensure we are not trying to debit the same coin twice
  def debit_coin(coin)
    ledger_entry_block = LedgerEntryBlock.new(:ledger_entry_type => LedgerEntryBlock::DEBIT, :coin_serial_number => coin.serial_number, :coin_face_value => coin.face_value)
    self.ledger.ledger_entry_blocks << ledger_entry_block
    self.coins << coin;

    @logger.debug("debit coin is ")
    @logger.debug(coin.inspect)

    self.balance += coin.face_value.to_i
    self.save
  end

  #there needs to be something better here if minting face values less or more than 1
  def credit_coin(serial_number) 
    coin = TicketDevilMintCoin.where(:digital_wallet_id => self.id, :serial_number => serial_number).first 
    #self.coins.delete(coin)
    @logger.debug("coin credit is ")
    @logger.debug(coin.inspect)
    ledger_entry_block = LedgerEntryBlock.new({:ledger_entry_type => LedgerEntryBlock::CREDIT, :coin_serial_number => coin.serial_number, :coin_face_value => coin.face_value})
    self.ledger.ledger_entry_blocks << ledger_entry_block
    @logger.debug "balance equation is (" + self.balance.to_s + " - " + coin.face_value.to_s + ")"
    self.balance = self.balance.to_i - coin.face_value.to_i
    @logger.debug "post equation is (" + self.balance.to_s + ")"
    self.save
    return coin
  end

  def request_credit_auth_from(receiver_wallet)
    return true
    #verify a secret has been shared
  end

  def check_balance
    init_logger unless @logger
    @logger.debug("The current balance of " + self.wallet_name.to_s + " #{self.balance}.")
    return self.balance
  end

  # in this method we need to use the public key of the coin to encrypt something, 
  # and the private key to decrypt something - but this only verifies the keys work
  # the wallet needs to create a secret with the public key, which can only be decrypted
  # by the private key
  # To verify that a coin is owned by a wallet the owning wallet serial number needs to match a secret
  # created by the coin
  # the public key of the new OWNER needs to encrypt data from the coin

  #this method is trying to prevent someone simply copying an existing coin to their wallet so the same keys appear in different wallets. 
  def bind_coin_to_wallet(coin)
    #return coin.digital_wallet == self
    #make new coin
    coin.tx_keys()
    auth_number = SecureRandom.uuid
    message_to_encrypt = "ATTEMPTING BIND: " + auth_number 
    coin_encrypted_message = Base64.encode64(coin.crypto_card.encrypt_message_with_public_key(message_to_encrypt))
    coin_decrypted_message = coin.crypto_card.decrypt_message_with_private_key(Base64.decode64(coin_encrypted_message))

    @logger.debug "Wallet details for bind_coin_to_wallet  " + self.inspect
    wallet_encrypted_message = Base64.encode64(self.crypto_card.encrypt_message_with_public_key(coin_decrypted_message))
    wallet_decrypted_message = self.crypto_card.decrypt_message_with_private_key(Base64.decode64(wallet_encrypted_message))

    throw "Coin keys are broken" unless message_to_encrypt == coin_decrypted_message
    throw "Wallet keys are broken" unless coin_decrypted_message == wallet_decrypted_message
    @logger.debug "Coin decrypted message is: " + coin_decrypted_message
    @logger.debug "Wallet decrypted message is: " + wallet_decrypted_message
    #coin.crypto_card
    
    return "AUTHORIZED"
  end
end

