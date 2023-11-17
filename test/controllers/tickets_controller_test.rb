require "test_helper"

class TicketsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ticket = tickets(:one)
  end

  test "should get index" do
    get tickets_url
    assert_response :success
  end

  test "should get new" do
    get new_ticket_url
    assert_response :success
  end

  test "should create ticket with anonymous user" do
    assert_difference("Ticket.count") do
      post tickets_url, params: { ticket: { category_id: @ticket.category_id, 
                                            cbc_amount: @ticket.cbc_amount, 
                                            creator_id: '', 
                                            description: 'anonymous user needs to build a pool 45', 
                                            rank: @ticket.rank, 
                                            ticket_from: "Franky Gehesrt", 
                                            ticket_to: "Anonymous user"} }
    end
    assert Ticket.where({ :description => 'anonymous user needs to build a pool 45' 
                        }).first.creator == User.where({:email => "anonymous@ticketme.com"}).first 
  end

  test "should create ticket" do
    assert_difference("Ticket.count") do
      post tickets_url, params: { ticket: { category_id: @ticket.category_id, cbc_amount: @ticket.cbc_amount, creator_id: User.all.first.id, description: @ticket.description, rank: @ticket.rank, ticket_from: @ticket.ticket_from, ticket_to: @ticket.ticket_to } }
    end

    assert_redirected_to ticket_url(Ticket.last)
  end

  test "should show ticket" do
    get ticket_url(@ticket)
    assert_response :success
  end

  test "should get edit" do
    get edit_ticket_url(@ticket)
    assert_response :success
  end

  test "should update ticket" do
    patch ticket_url(@ticket), params: { ticket: { category_id: @ticket.category_id, cbc_amount: @ticket.cbc_amount, creator_id: @ticket.creator_id, description: @ticket.description, rank: @ticket.rank, ticket_from: @ticket.ticket_from, ticket_to: @ticket.ticket_to } }
    assert_redirected_to ticket_url(@ticket)
  end

  test "should destroy ticket" do
    assert_difference("Ticket.count", -1) do
      delete ticket_url(@ticket)
    end

    assert_redirected_to tickets_url
  end
end
