class TicketsUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :tickets_users do |t|
      t.integer :user_id
      t.integer :ticket_id
    end
  end
end
