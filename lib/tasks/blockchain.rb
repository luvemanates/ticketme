require 'digest'

class Block
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :blockchain
  has_one :merkle_tree_node

  #attr_reader :index, :timestamp, :data, :previous_hash, :hash


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
    previous_block = Block.where(:blockchain => self.blockchain, :created_at => :desc).first
    self.index = previous_block.index.to_i + 1
    self.previous_hash = previous_block.current_hash
  end

  def add_merkle_leaf
    unless self.merkle_tree.nil?
      previous_block = Block.where(:created_at => :desc).first
      self.previous_hash = previous_block.current_hash if not previous_block.nil?
      @logger.debug( "Adding merkle tree leaf")
      merkle_leaf = self.merkle_tree.add_leaf(:block => self, :stored_data => "#{self.index}#{self.created_at}#{self.receiver_wallet_address}#{self.receiver_wallet_balance}#{self.signature}#{previous_hash}")
      self.current_hash = merkle_leaf.merkle_hash
      mr = MerkleTreeNode.where(:merkle_tree => self.blockchain.merkle_tree, :node_type => MerkleTreeNode::ROOT).first
      self.merkle_root = mr.merkle_hash
    end
  end


  private

end

class Blockchain
  has_many :blocks
  has_one :merkle_tree

  field :name

  def add_block(params)
    block = Block.new(:blockchain => self,
          :sender_wallet_address => params[:sender_wallet_address],
          :sender_wallet_balance => params[:sender_wallet_balance],
          :receiver_wallet_address => params[:receiver_wallet_address],
          :receiver_wallet_balance => params[:receiver_wallet_balance],
          :public_key => Base58.encode(params[:sender_public_key]),
          :transaction_amount => params[:transaction_amount],
          :sender_signature => params[:sender_signature],
          :verifiable_data => params[:verifiable_data])
    #self.blocks << block
    block.save
    return block
  end

  private
end
