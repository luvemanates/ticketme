namespace :ticketme do
  desc "TODO"
  task calc_rank: :environment do
    tickets = Ticket.all
    for ticket in tickets 
      rank = ticket.users.count
      unless ticket.rank == rank
        ticket.rank = rank
        ticket.save
        puts "For itcket: " + ticket.id.to_s + " rank is " + ticket.rank.to_s
      end
    end
  end

end
