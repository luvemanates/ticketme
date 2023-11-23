require "test_helper"

class TicketTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "has many users" do
    @user = User.new(:email => "jenny@gmail.com", :display_name => "bob", :password => 'deftones', :password_confirmation => 'deftones')
    @ticket  = Ticket.new(:ticket_to => "bob jones", 
                          :ticket_from => "Jenny jones", 
                          :description => "please fix the oven", 
                          :cbc_amount => "1000", :creator => @user)
    assert @user.save
    assert @ticket.save
    assert @user.tickets << @ticket
  end
end
