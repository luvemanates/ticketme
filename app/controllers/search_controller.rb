class SearchController < ApplicationController

  #before_action :search_params

  def show 
    search_params = params[:search_params]
    page = params[:page]
    puts "search params are" + search_params
    puts "page is " + page
    @tickets = Ticket.all
  end

  def create
    search_params = params[:search_params]
    page = params[:page]
    redirect_to :action => :show, :search_params => search_params, :page => page
  end

=begin
  private
  def get_params
    @search_params = params[:search_params]
    text = @search_params[:text]
    page = @search_params[:page]
    @tickets = Tikcket.paginate(:page => page, :conditions => [ "match(ticket_to, ticket_from, description) against (?)", text] )
    if @tickets.empty?
      @tickets = Ticket.paginate(:page => page, :conditions => [ "ticket_to like ? or ticket_from like ? or description like ?", text, text, text])
    end

  end
=end
end
