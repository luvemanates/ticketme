class TicketsController < ApplicationController
  before_action :set_ticket, only: %i[ show edit update destroy ]

  # GET /tickets or /tickets.json
  def index
    unless params[:page]
      @page = 1 
    else
      @page = params[:page]
    end
    @tickets = Ticket.all.includes(:creator).order(:created_at => :desc).paginate(:page => @page, :per_page => 5)
  end

  # GET /tickets/1 or /tickets/1.json
  def show
    @ticket_comments = @ticket.ticket_comments
  end

  # GET /tickets/new
  def new
    @ticket = Ticket.new
    if user_signed_in?
      @ticket.creator = current_user 
    else
      @ticket.creator = User.where(:email => 'anonymous@ticketme.com').first
    end
  end

  # PUT /tickets/1/bcc
  def bcc
    @ticket = Ticket.find(params[:ticket_id])
    #increase the rank
    if user_signed_in?
      if current_user.tickets.include? @ticket
        flash[:notice] = "You are already watching this ticket."
      else
        current_user.tickets << @ticket 
        @ticket.rank = @ticket.rank + 1
        @ticket.save
        flash[:notice] = "Blind carbon copied this ticket.  It will now show up as one of your watched tickets."
      end
    else
      flash[:notice] = "You must be signed in to BCC a ticket."
    end
    #puts @ticket.to_yaml
    #puts "bcc method"
    redirect_to ticket_path(@ticket)
  end
  
  # GET /tickets/1/edit
  def edit
  end

  # POST /tickets or /tickets.json
  def create
    @ticket = Ticket.new(ticket_params)
    creator = current_user #@ticket.creator
    unless creator.is_a? User
      @ticket.creator = User.find_by_email('anonymous@ticketme.com')
    end
    respond_to do |format|
      if @ticket.save
        @ticket.users << @ticket.creator
        format.html { redirect_to ticket_url(@ticket), notice: "Ticket was successfully created." }
        format.json { render :show, status: :created, location: @ticket }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ticket.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tickets/1 or /tickets/1.json
  def update
    @ticket = Ticket.new(ticket_params)
    creator = current_user #@ticket.creator
    unless creator.is_a? User
      @ticket.creator = User.find_by_email('anonymous@ticketme.com')
    end
    respond_to do |format|
      if @ticket.save
        format.html { redirect_to ticket_url(@ticket), notice: "Ticket was successfully created based on the old ticket." }
        format.json { render :show, status: :ok, location: @ticket }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ticket.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tickets/1 or /tickets/1.json
  def destroy
    @ticket.destroy!

    respond_to do |format|
      format.html { redirect_to tickets_url, notice: "Ticket was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ticket
      @ticket = Ticket.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ticket_params
      params.require(:ticket).permit(:ticket_to, :ticket_from, :description, :cbc_amount, :creator_id, :rank, :category_id)
    end
end
