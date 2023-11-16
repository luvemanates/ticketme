class TicketsUsersIndexes < ActiveRecord::Migration[7.1]
  def change
    add_index :users, :email, unique: true
    add_index :users, :display_name
    add_index :users, :phone_number
    add_index :tickets, :description
    add_index :tickets, :creator_id
    add_index :tickets, :category_id
    add_index :tickets, :ticket_to
    add_index :tickets, :ticket_from
  end
end
