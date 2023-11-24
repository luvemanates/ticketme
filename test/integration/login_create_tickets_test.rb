require "test_helper"

class LoginCreateTicketsTest < ActionDispatch::IntegrationTest
  test "assert get root" do
    get root_path
    assert_response :success
  end

  #create user
  test "create user from devise" do
    get new_user_registration_path
    assert_response :success
    assert_difference("User.count") do
      post user_registration_path, :params => {:user => { :email => 'user@user.com', :password => 'deftones', :password_confirmation => 'deftones' } }
    end
  end

  test "bcc a ticket" do
    u = User.create({:email => 'user@user.com', :password => 'deftones', :password_confirmation => 'deftones' })
    get new_user_registration_path
    assert_response :success
    post user_session_path, :params => { :user => { :email => 'user@user.com', :password => 'deftones' } }
    assert_redirected_to root_path
    ticket = Ticket.first
    assert_not u.tickets.include? ticket 
    put ticket_bcc_path(ticket)
    assert u.tickets.include? ticket 
  end

  test "create user behind scenes and then create ticket after login" do
    u = User.create({:email => 'user@user.com', :password => 'deftones', :password_confirmation => 'deftones' })
    get new_user_registration_path
    assert_response :success
    post user_session_path, :params => { :user => { :email => 'user@user.com', :password => 'deftones' } }
    assert_redirected_to root_path
    get new_ticket_path
    assert_difference("Ticket.count") do
      post tickets_url, params: { ticket: { category_id: 3, 
                                            cbc_amount: '4000', 
                                            creator_id: u.id, 
                                            description: 'anonymous user needs to build a pool 45', 
                                            rank: 5, 
                                            ticket_from: "Franky Gehesrt", 
                                            ticket_to: "Anonymous user"} }
    end
    assert u.tickets.include? Ticket.last
  end
end
