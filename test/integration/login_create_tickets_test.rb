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

  test "can search existing tickets" do
    get "/search/show/anonymous/1"
    assert_response :success
    post "/search/one/1", :params => {:posted_search_params => 'table', :posted_page => 1 }
    assert_response :redirect
    follow_redirect!
    #assert @tickets.includes?(Ticket.first) #.where(:ticket_to => 'one')
    assert_select "table" do
      assert_select "td.ticket-description" 
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

  test "assert can create a ticket comment" do
    @ticket_comment = ticket_comments(:one)
    u = User.create({:email => 'user@user.com', :password => 'deftones', :password_confirmation => 'deftones' })
    get new_user_registration_path
    assert_response :success
    post user_session_path, :params => { :user => { :email => 'user@user.com', :password => 'deftones' } }
    assert_redirected_to root_path
    assert_difference("TicketComment.count") do
      post ticket_comments_url, :params => { :ticket_comment => { :ticket_id => Ticket.first.id, 
                                                                 :comment => "This should be worth more."} }
    end

    assert_redirected_to ticket_url(TicketComment.last.ticket)
  end
end
