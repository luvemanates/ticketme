require 'digest'
require 'mongoid'
require 'logger'
require_relative 'merkle'

class Ledger
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :digital_wallet, :index => true
  has_many :ledger_entry_blocks #object type is LedgerEntryBlock (has_many)
  has_one :merkle_tree

  field :ledger_name
  field :current_ledger_amount #should be all the debit - all the credits

  attr_accessor :logger
  #It would probably be better accounting to have a balance update in the entry
  #field :new_balance
  after_find :init_logger
  before_create :pre_init
  before_create :init_logger
  before_create :create_merkle_tree

  def pre_init
    self.ledger_name = "Default Ledger Name" if self.ledger_name.nil?
    self.current_ledger_amount = 0 if self.current_ledger_amount.nil?
  end

  def init_logger
    @logger = Logger.new(Logger::DEBUG)
  end

  def create_merkle_tree
    mt = MerkleTree.new
    mt.ledger = self
    mt.save
    self.merkle_tree = mt
  end

  def new_entry(new_ledger_block)
    self.ledger_entry_blocks << new_ledger_block
    update_amount
  end

  def update_amount
    credits = 0
    debits = 0
    for entry_block in self.ledger_entry_blocks
      if entry_block.ledger_entry_type == LedgerEntryBlock::CREDIT
        credits -= entry_block.entry_amount.to_i
      elsif entry_block.ledger_entry_type == LedgerEntryBlock::DEBIT
        debits += entry_block.entry_amount.to_i
      end
    end
    current_ledger_amount = debits - credits
    return current_ledger_amount
  end

  def can_verify_current_ledger_amount?
    credits = 0
    debits = 0
    for entry_block in self.ledger_entry_blocks
      if entry_block.ledger_entry_type == LedgerEntryBlock::CREDIT
        credits -= entry_block.entry_amount
      elsif entry_block.ledger_entry_type == LedgerEntryBlock::DEBIT
        debits += entry_block.entry_amount
      end
    end
    current_tally = debits - credits
    if current_tally == @current_ledger_amount #should be all the debit - all the credits
      return true
    else
      return false
    end
  end
end

class LedgerEntryBlock

  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :ledger, :index => true
  has_one :merkle_tree_node


#  BALANCE = "balance"

  field :entry_amount
  field :balance
  field :ledger_entry_type #credit or debit
  field :coin_serial_number
  field :coin_face_value
  field :current_hash
  field :previous_hash

  attr_accessor :logger
  #It would probably be better accounting to have a balance update in the entry
  #field :new_balance
  after_find :init_logger
  before_create :pre_init
  before_create :init_logger
  before_create :update_balance, :calculate_hash
  #before_create :add_merkle_leaf
  CREDIT = "credit"
  DEBIT = "debit"

  def pre_init
    @logger = Logger.new(Logger::DEBUG)
    
    @logger.debug( "inspecting params passed to ledger")
  end

  def update_balance
    previous_block = self.ledger.ledger_entry_blocks.order(:created_at => :desc).first
    if not previous_block.nil?
      self.balance = previous_block.balance unless previous_block.balance.nil?
    end
    if self.balance == nil 
      self.balance = 0
    end
    self.balance = self.balance.to_i + self.coin_face_value.to_i if self.ledger_entry_type == DEBIT
    self.balance = self.balance.to_i - self.coin_face_value.to_i if self.ledger_entry_type == CREDIT
  end

  def calculate_hash
    previous_block = self.ledger.ledger_entry_blocks.order(:created_at => :desc).first
    if previous_block.nil?
      self.previous_hash = "Genesis Block" 
    else
      self.previous_hash = previous_block.current_hash
    end
    self.current_hash = Digest::SHA256.hexdigest("#{self.id}#{self.created_at}#{self.coin_serial_number}#{self.balance}#{self.ledger_entry_type}#{previous_hash}")
  end

  def add_merkle_leaf
    if ledger.merkle_tree
      previous_block = self.ledger.ledger_entry_blocks.order(:created_at => :desc).first
      previous_hash = previous_block.current_hash if not previous_block.nil?
      mt = self.ledger.merkle_tree 
      @logger.debug( "Adding merkle tree leaf")
      merkle_leaf = mt.add_leaf(:ledger_entry_block_id => self.id, :stored_data => "#{self.id}#{self.created_at}#{self.coin_serial_number}#{self.balance}#{self.ledger_entry_type}#{previous_hash}")
    end
  end

  def init_logger
    @logger = Logger.new(Logger::DEBUG)
  end


end


