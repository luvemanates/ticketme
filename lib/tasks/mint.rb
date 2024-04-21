require 'mongoid'
require 'securerandom'
require_relative 'ledger'
require_relative 'centralized_exchange'
require_relative 'ticketdevil_cryptography'

#I think this class should have a digital wallet

#One of these classes need a way to make change and mint smaller coins

class TicketDevilMintingBank

  attr_accessor :time_elapsed
  attr_accessor :total_coins
  attr_accessor :ledger
  attr_accessor :exchange
  attr_accessor :logger

  def initialize
    @logger = Logger.new(Logger::DEBUG)
    @ledger = Ledger.new(:ledger_name => 'TicketDevilMint Ledger')
    @total_coins = 0
    @time_elapsed = 0
    @exchange = CentralizedExchange.new
  end

  def mint(params)
    coin = TicketDevilMintCoin.new(:face_value => params[:face_value], :digital_wallet => params[:digital_wallet])
    @logger.debug "coin.inspect for new minted coin face value check"
    @logger.debug coin.inspect
    #while @exchange.is_already_minted_coin?(coin)
    #  @logger.warn 'This coin has already been minted, so it will not be added to the exchange, or added to the ledger.'
    #  coin = TicketDevilMintCoin.new(:face_value => coin_face_value)
    #end
    coin.save
    @ledger = Ledger.new(:ledger_name => 'TicketDevilMint Ledger') if @ledger.nil?
    @exchange.coins << coin 
    @total_coins = @total_coins.to_i + params[:face_value].to_i
    ledger_entry_block = LedgerEntryBlock.new(:ledger_entry_type => LedgerEntryBlock::DEBIT, :coin_serial_number => coin.serial_number, :coin_face_value => coin.face_value)
    ledger_entry_block.ledger = @ledger
    @ledger.new_entry(ledger_entry_block)
    return coin
  end

end


# A non fungible coin
# Needs its own private key that is created for any new owners of the coin
class TicketDevilMintCoin #or ticketdevil coin
  include Mongoid::Document
  include Mongoid::Timestamps

  field :serial_number
  index({ serial_number: 1}, { unique: true })
  field :created_at
  field :face_value
  has_one :crypto_card, :as => :crypto_card_carrier, :class_name => 'TicketDevilCryptography'
  belongs_to :digital_wallet, :index => true

  #attr_accessor :serial_number
  #attr_writer :created_at
  #attr_accessor :face_value
  attr_accessor :logger
  #attr_accessor :crypto_card 
  before_create :pre_init
  after_create :do_crypto_card
  after_find :init_logger
  before_create :init_logger

  def pre_init
    @logger = Logger.new(Logger::DEBUG)
    @logger.debug "ticketdevil mint init params is "
    if self.face_value.nil?
      #puts 'setting face_value to 1'
      self.face_value = 1
    end
    if self.serial_number.nil?
      self.serial_number = SecureRandom.uuid
    end
    if self.digital_wallet.nil?
      throw "No wallet found"
    end
  end

  def init_logger
    @logger = Logger.new(Logger::DEBUG)
    @logger.debug("initialized logger in TicketDevilMintCoin")
  end
  
  def do_crypto_card
    crypto_card = TicketDevilCryptography.new(:card_name => "coin card")
    crypto_card.crypto_card_carrier = self
    @crypto_card = crypto_card.save 
  end

  def tx_keys
    old_card = self.crypto_card
    new_crypto_card = TicketDevilCryptography.new(:card_name => "coin card")
    new_crypto_card.crypto_card_carrier = self
    new_crypto_card.save 
    self.crypto_card = new_crypto_card
    self.save
    old_card.destroy
  end
end
