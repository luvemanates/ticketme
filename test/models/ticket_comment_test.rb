require "test_helper"

class TicketCommentTest < ActiveSupport::TestCase
  test "can create ticket comment" do
    @ticket = Ticket.first
    @user = User.first
    @ticket_comment = TicketComment.new(:comment => "We should be balling.", :user_id => @user.id, :ticket_id => @ticket.id)
    assert_difference("TicketComment.count") do
      assert @ticket_comment.save
    end
  end
end
