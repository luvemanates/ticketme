
require '../../config/environment'
require 'base58'
require 'mongoid'
require_relative 'digital_wallet'
require_relative 'blockchain'


dw = DigitalWallet.new(:wallet_name => 'TicketDevil Bank Wallet')
dw.save
mw = DigitalWallet.new(:wallet_name => 'TicketDevil Mint Wallet')
mw.save
blockchain = Blockchain.new(:name => "TicketDevil blockchain")
blockchain.save
loop do
  random_secret = (0...16).map { (65 + rand(26)).chr }.join 
  signature = mw.crypto_card.sign( random_secret )
  verified = mw.crypto_card.verify(signature, random_secret)
  throw "Could not verify signature" if not verified
  tmp = Base64.encode64(signature)
  puts tmp
  puts "trying to encode twice"
  tmp = Base64.encode64(tmp)
  puts tmp
  block = blockchain.add_block( 
            :sender_wallet_address => mw.wallet_identification, 
            :sender_wallet_balance => mw.balance,
            :receiver_wallet_address => dw.wallet_identification, 
            :receiver_wallet_balance => dw.balance, 
            :sender_public_key => Base64.encode64(dw.crypto_card.public_key.to_s),
            :transaction_amount => 1,
            :sender_signature => Base64.encode64(signature),
            :verifiable_data => random_secret)
  puts block.inspect
  block.save
  puts block.inspect
end
