require "application_system_test_case"

class TicketsTest < ApplicationSystemTestCase
  setup do
    @ticket = tickets(:one)
  end

  test "visiting the index" do
    visit tickets_url
    assert_selector "h1", text: "Tickets"
  end

  test "should create ticket" do
    visit tickets_url
    click_on "New ticket"

    fill_in "Category", with: @ticket.category_id
    fill_in "Cbc amount", with: @ticket.cbc_amount
    fill_in "Creator", with: @ticket.creator_id
    fill_in "Description", with: @ticket.description
    fill_in "Rank", with: @ticket.rank
    fill_in "Ticket from", with: @ticket.ticket_from
    fill_in "Ticket to", with: @ticket.ticket_to
    click_on "Create Ticket"

    assert_text "Ticket was successfully created"
    click_on "Back"
  end

  test "should update Ticket" do
    visit ticket_url(@ticket)
    click_on "Edit this ticket", match: :first

    fill_in "Category", with: @ticket.category_id
    fill_in "Cbc amount", with: @ticket.cbc_amount
    fill_in "Creator", with: @ticket.creator_id
    fill_in "Description", with: @ticket.description
    fill_in "Rank", with: @ticket.rank
    fill_in "Ticket from", with: @ticket.ticket_from
    fill_in "Ticket to", with: @ticket.ticket_to
    click_on "Update Ticket"

    assert_text "Ticket was successfully updated"
    click_on "Back"
  end

  test "should destroy Ticket" do
    visit ticket_url(@ticket)
    click_on "Destroy this ticket", match: :first

    assert_text "Ticket was successfully destroyed"
  end
end
