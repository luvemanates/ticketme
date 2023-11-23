require "test_helper"

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "create a user" do
    user = User.new(:email => "test@test.com", 
                    :password => "Whatever", 
                    :password_confirmation => "Whatever", 
                    :display_name => "Dude cool", 
                    :phone_number => "5624567894") 
    assert user.save
  end

  test "user can make a ticker, 
        and be added as creator,
        and ticket includes the user" do
    user = User.new(:email => "test@test.com", 
                    :password => "Whatever", 
                    :password_confirmation => "Whatever", 
                    :display_name => "Dude cool", 
                    :phone_number => "5624567894") 
    assert user.save
    ticket  = Ticket.new(:ticket_to => "bob jones", 
                          :ticket_from => "Jenny jones", 
                          :description => "please fix the oven", 
                          :cbc_amount => "1000", :creator => user)
    assert ticket.save
    assert user.tickets << ticket
    assert user.created_tickets.include?(ticket)
    assert ticket.creator == user
  end
end
