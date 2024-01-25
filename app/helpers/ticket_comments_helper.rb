module TicketCommentsHelper
  def comment_color(current_ticket_count)
    current_ticket_count = 1 unless current_ticket_count 
    color_selector = current_ticket_count % 2 
    ticket_colors = ["white", "gray"] 
    ticket_color = ticket_colors[color_selector] 
    return ticket_color
  end
end
