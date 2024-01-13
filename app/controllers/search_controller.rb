class SearchController < ApplicationController

  #before_action :search_params

  def show 
    @search_params = params[:search_params]
    @page = params[:page]
    @terms = @search_params.gsub(/\+/, ' ') #turn +'s back into spaces for searching again - and for the query
    @tickets = Ticket.where("match(ticket_to, ticket_from, description) against (?)", @terms).paginate(:page => @page, :per_page => 5)
    @count = Ticket.where("match(ticket_to, ticket_from, description) against (?)", @terms).count
    @aterms = ''
    if @count == 0
      sterms = params[:search_params].split('+')
      sterms.each do |term|
        @aterms = @aterms + '%' + term
      end
      @aterms = @aterms + "%"
      @tickets =  Ticket.where([ "ticket_from like ? or ticket_to like ? or description like ?", @aterms, @aterms, @aterms]).paginate(:page => @page, :per_page => 5)
      @count =  Ticket.where([ "ticket_from like ? or ticket_to like ? or description like ?", @aterms, @aterms, @aterms]).count
    end
    #puts "search params are " + @search_params
    #puts "page is " + @page
  end

  def create
    @search_params = params[:posted_search_params]
    @page = params[:posted_page]
    #@search_params = @search_params #.parameterize('+')
    redirect_to :action => :show, :search_params => @search_params, :page => @page
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
