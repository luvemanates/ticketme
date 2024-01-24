module TicketsHelper
  def ticket_color(current_ticket_count)
    current_ticket_count = 1 unless current_ticket_count 
    color_selector = current_ticket_count % 4 
    ticket_colors = ["blue", "red", "green", "yellow"] 
    ticket_color = ticket_colors[color_selector] 
    return ticket_color
  end

  def ticket_tape_version(current_ticket_count)
    current_ticket_count = 1 unless current_ticket_count 
    tape_selector = current_ticket_count % 3 
    ticket_tape = ["top_left", "middle", "top_right"] 
    ticket_tape_select = ticket_tape[tape_selector] 
    return ticket_tape_select
  end
end
