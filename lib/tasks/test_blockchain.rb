
require '../../config/environment'
require 'mongoid'
require_relative 'mint'
require_relative 'digital_wallet'
require_relative 'blockchain'
require 'base58'


dw = DigitalWallet.new(:wallet_name => 'TicketDevil Bank Wallet')
mw = DigitalWallet.new(:wallet_name => 'TicketDevil Mint Wallet')
blockchain = Blockchain.new(:name => "TicketDevil blockchain")
blockchain.save
loop do
  random_secret = (0...16).map { (65 + rand(26)).chr }.join 
  signature = mw.crypto_card.public_key.sign( random_secret )
  block = blockchain.add_block( 
            :sender_wallet_address => mw.wallet_address, 
            :sender_wallet_balance => mw.wallet_balance,
            :receiver_wallet_address => dw.wallet_address, 
            :receiver_wallet_balance => dw.wallet_balance, 
            :sender_public_key => Base58.encode(dw.crypto_card.public_key),
            :sender_signature => signature,
            :verifiable_data => random_secret)
  block.save
end
