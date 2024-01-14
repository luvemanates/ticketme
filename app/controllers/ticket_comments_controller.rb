class TicketCommentsController < ApplicationController
  before_action :get_user

  # GET /ticket_comments/new
  def new
    @ticket_comment = TicketComment.new
    @ticket_id = params[:ticket_id]
  end

  # POST /ticket_comments or /ticket_comments.json
  def create
    @ticket_comment = TicketComment.new(ticket_comment_params.merge(:user_id => @user.id))

    respond_to do |format|
      if @ticket_comment.save
        format.html { redirect_to ticket_url(@ticket_comment.ticket), notice: "Ticket comment was successfully created." }
        format.json { render :show, status: :created, location: @ticket_comment }
      else
        puts @ticket_comment.errors.inspect
        @ticket_id = params[:ticket_id]
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ticket_comment.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Get user -- needed to leave comments
    def get_user
      redirect_to new_user_session_path and return unless current_user
      @user = current_user
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_ticket_comment
      @ticket_comment = TicketComment.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ticket_comment_params
      params.require(:ticket_comment).permit(:ticket_id, :user_id, :comment)
    end
end
