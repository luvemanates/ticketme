require "test_helper"

class TicketCommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ticket_comment = ticket_comments(:one)
  end

  test "should get index" do
    get ticket_comments_url
    assert_response :success
  end

  test "should get new" do
    get new_ticket_comment_url
    assert_response :success
  end

  test "should create ticket_comment" do
    assert_difference("TicketComment.count") do
      post ticket_comments_url, params: { ticket_comment: { comment: @ticket_comment.comment, ticket_id: @ticket_comment.ticket_id, user_id: @ticket_comment.user_id } }
    end

    assert_redirected_to ticket_comment_url(TicketComment.last)
  end

  test "should show ticket_comment" do
    get ticket_comment_url(@ticket_comment)
    assert_response :success
  end

  test "should get edit" do
    get edit_ticket_comment_url(@ticket_comment)
    assert_response :success
  end

  test "should update ticket_comment" do
    patch ticket_comment_url(@ticket_comment), params: { ticket_comment: { comment: @ticket_comment.comment, ticket_id: @ticket_comment.ticket_id, user_id: @ticket_comment.user_id } }
    assert_redirected_to ticket_comment_url(@ticket_comment)
  end

  test "should destroy ticket_comment" do
    assert_difference("TicketComment.count", -1) do
      delete ticket_comment_url(@ticket_comment)
    end

    assert_redirected_to ticket_comments_url
  end
end
