class CreateTicketComments < ActiveRecord::Migration[7.1]
  def change
    create_table :ticket_comments do |t|
      t.integer :ticket_id
      t.integer :user_id
      t.string :comment

      t.timestamps
    end
    add_index :ticket_comments, [:ticket_id, :user_id ]
  end
end
