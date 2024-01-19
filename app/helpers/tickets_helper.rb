module TicketsHelper
  def ticket_color(current_ticket_count)
    current_ticket_count = 1 unless current_ticket_count 
    color_selector = current_ticket_count % 4 
    ticket_colors = ["blue", "red", "green", "yellow"] 
    ticket_color = ticket_colors[color_selector] 
    return ticket_color
  end
end
