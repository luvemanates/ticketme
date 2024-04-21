require 'digest'

class Block
  attr_reader :index, :timestamp, :data, :previous_hash, :hash

  def initialize(index, timestamp, data, previous_hash)
    @index = index
    @timestamp = timestamp
    @data = data
    @previous_hash = previous_hash
    @hash = calculate_hash
  end

  private

  def calculate_hash
    Digest::SHA256.hexdigest("#{index}#{timestamp}#{data}#{previous_hash}")
  end
end

class Blockchain
  attr_accessor :chain

  def initialize
    @chain = [create_genesis_block]
  end

  def add_block(data)
    previous_block = @chain.last
    index = @chain.length
    timestamp = Time.now
    previous_hash = previous_block.hash
    added_chain = Block.new(index, timestamp, data, previous_hash)
    @chain << added_chain
    return added_chain
  end

  private

  def create_genesis_block
    Block.new(0, Time.now, "Genesis Block", "0")
  end
end
