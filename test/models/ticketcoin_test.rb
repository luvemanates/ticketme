require "test_helper"
require_relative '../../lib/tasks/merkle'
require_relative '../../lib/tasks/digital_wallet'
require_relative '../../lib/tasks/mint'

class TicketCoinTest < ActiveSupport::TestCase

  test "the truth" do
     assert true
  end

  test "test ledger with merkle trees" do
    wallet = DigitalWallet.new(:wallet_name => 'test wallet')
    mint = TicketDevilMintingBank.new
    coin = mint.mint(:face_value => 1, :digital_wallet => wallet)
    assert wallet.save
    assert wallet.debit_coin(coin)
    coin = mint.mint(:face_value => 1, :digital_wallet => wallet)
    assert wallet.debit_coin(coin)
    coin = mint.mint(:face_value => 1, :digital_wallet => wallet)
    assert wallet.debit_coin(coin)
    root_node = MerkleTreeNode.where(:id => wallet.ledger.merkle_tree.root_node_id).first
    assert root_node.node_type == 'ROOT'
    assert root_node.children
  end

  test "test merkle tree" do
    mt = MerkleTree.new()
    mt.save

    leaf1 = mt.add_leaf(:stored_data => 'leaf 1')
    leaf2 = mt.add_leaf(:stored_data => 'leaf 2')
    assert_equal "leaf 1",  leaf1.stored_data
    assert_equal "ROOT", leaf2.parent.node_type
    assert_equal 2, mt.get_leaf_height

    mt.add_leaf({:stored_data => 'leaf 3'})
    mt.add_leaf({:stored_data => 'leaf 4'})
    assert_equal 3, mt.get_leaf_height
    assert MerkleTreeNode.where(:stored_data => 'leaf 3').first.parent.node_type == "PARENT"

    mt.add_leaf({:stored_data => 'leaf 5'})
    mt.add_leaf({:stored_data => 'leaf 6'})
    assert_equal 4, mt.get_leaf_height
    assert MerkleTreeNode.where(:stored_data => 'leaf 3').first.parent.node_type == "PARENT"

    mt.add_leaf({:stored_data => 'leaf 7'})
    mt.add_leaf({:stored_data => 'leaf 8'})
    assert MerkleTreeNode.where(:stored_data => 'leaf 5').first.parent.node_type == "PARENT"
    assert MerkleTreeNode.where(:stored_data => 'leaf 5').first.parent.parent.node_type == "PARENT"
    assert_equal "ROOT",  MerkleTreeNode.where(:stored_data => 'leaf 5').first.parent.parent.parent.parent.node_type
    assert_equal 4,  mt.get_leaf_height

    mt.add_leaf({:stored_data => 'leaf 9'})
    mt.add_leaf({:stored_data => 'leaf 10'})
    assert_equal 5,  mt.get_leaf_height
  end

  test "can create a ticket with a user" do
    @user = User.new(:email => 'blah@blah.com', :password => 'deftones', :password_confirmation => 'deftones')
    assert_difference("User.count") do
      @user.save
    end
    @user.save
    assert_difference("Ticket.count") do
      @ticket  = Ticket.new(:ticket_to => "bob jones", 
                          :ticket_from => "Jenny jones", 
                          :description => "please fix the oven", 
                          :cbc_amount => "1000", :creator => @user)
      assert @ticket.save
    end
  end
end
