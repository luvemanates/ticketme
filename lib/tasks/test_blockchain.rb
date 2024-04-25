
require '../../config/environment'
require 'base58'
require 'mongoid'
require_relative 'digital_wallet'
require_relative 'blockchain'


dw = DigitalWallet.where(:wallet_name => 'TicketDevil Bank Wallet').first
unless dw
  dw = DigitalWallet.new(:wallet_name => 'TicketDevil Bank Wallet')
  dw.save
end
mw = DigitalWallet.where(:wallet_name => 'TicketDevil Mint Wallet').first
unless mw
  mw = DigitalWallet.new(:wallet_name => 'TicketDevil Mint Wallet')
  mw.save
end
blockchain = Blockchain.where(:name => "TicketDevil blockchain").first
unless blockchain
  blockchain = Blockchain.new(:name => "TicketDevil blockchain")
  blockchain.save
end
loop do
  random_secret = (0...16).map { (65 + rand(26)).chr }.join 
  signature = mw.crypto_card.sign( random_secret )
  verified = mw.crypto_card.verify(signature, random_secret)
  throw "Could not verify signature" if not verified
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
