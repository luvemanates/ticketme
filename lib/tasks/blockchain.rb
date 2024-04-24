require 'digest'
require 'base58'

class Block
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :blockchain
  has_one :merkle_tree_node

  #attr_reader :index, :timestamp, :data, :previous_hash, :hash
  attr_accessor :logger


  field :index
  field :sender_wallet_address
  field :sender_wallet_balance
  field :receiver_wallet_address
  field :receiver_wallet_balance
  field :transaction_amount
  field :merkle_root
  field :current_hash
  field :previous_hash
  field :sender_public_key
  field :sender_signature
  field :verifiable_data

  before_create :pre_init
  before_create :add_merkle_leaf



  def pre_init
    @logger = Logger.new(Logger::DEBUG)
    previous_block = Block.where(:blockchain_id => self.blockchain.id).order(:created_at => :desc).first
    if previous_block.nil?
      self.index = 1
      self.previous_hash = ''
    else
      self.index = previous_block.index.to_i + 1
      self.previous_hash = previous_block.current_hash
    end
  end

  def add_merkle_leaf
    unless self.blockchain.merkle_tree.nil?
      previous_block = Block.where(:blockchain_id => self.blockchain.id).order(:created_at => :desc).first
      if previous_block
        self.previous_hash = previous_block.current_hash if not previous_block.nil?
      else
        self.previous_hash = ''
      end
      @logger.debug( "Adding merkle tree leaf")
      stored_data = "#{self.index}#{self.created_at}#{self.receiver_wallet_address}#{self.receiver_wallet_balance}"
      stored_data = stored_data + Base64.encode64(self.sender_signature.to_s)
      stored_data = stored_data + previous_hash.to_s
      merkle_leaf = self.blockchain.merkle_tree.add_leaf(:block => self, :stored_data => stored_data)
      self.current_hash = merkle_leaf.merkle_hash
      mr = MerkleTreeNode.where(:merkle_tree => self.blockchain.merkle_tree, :node_type => MerkleTreeNode::ROOT).first
      self.merkle_root = mr.merkle_hash
    end
  end


  private

end

class Blockchain
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :blocks
  has_one :merkle_tree

  field :name

  before_create :pre_init

  def pre_init
    if self.merkle_tree.nil?
      mt = MerkleTree.new(:blockchain => self)
      mt.save
      self.merkle_tree = mt
    end
  end

  def add_block(params)
    block = Block.new(:blockchain => self,
          :sender_wallet_address => params[:sender_wallet_address],
          :sender_wallet_balance => params[:sender_wallet_balance],
          :receiver_wallet_address => params[:receiver_wallet_address],
          :receiver_wallet_balance => params[:receiver_wallet_balance],
          :sender_public_key => params[:sender_public_key],
          :transaction_amount => params[:transaction_amount],
          :sender_signature => params[:sender_signature],
          :verifiable_data => params[:verifiable_data])
    #self.blocks << block
    block.save
    return block
  end

  private
end
