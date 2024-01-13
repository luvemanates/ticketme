require "application_system_test_case"

class TicketCommentsTest < ApplicationSystemTestCase
  setup do
    @ticket_comment = ticket_comments(:one)
  end

  test "visiting the index" do
    visit ticket_comments_url
    assert_selector "h1", text: "Ticket comments"
  end

  test "should create ticket comment" do
    visit ticket_comments_url
    click_on "New ticket comment"

    fill_in "Comment", with: @ticket_comment.comment
    fill_in "Ticket", with: @ticket_comment.ticket_id
    fill_in "User", with: @ticket_comment.user_id
    click_on "Create Ticket comment"

    assert_text "Ticket comment was successfully created"
    click_on "Back"
  end

  test "should update Ticket comment" do
    visit ticket_comment_url(@ticket_comment)
    click_on "Edit this ticket comment", match: :first

    fill_in "Comment", with: @ticket_comment.comment
    fill_in "Ticket", with: @ticket_comment.ticket_id
    fill_in "User", with: @ticket_comment.user_id
    click_on "Update Ticket comment"

    assert_text "Ticket comment was successfully updated"
    click_on "Back"
  end

  test "should destroy Ticket comment" do
    visit ticket_comment_url(@ticket_comment)
    click_on "Destroy this ticket comment", match: :first

    assert_text "Ticket comment was successfully destroyed"
  end
end
