class CreateTickets < ActiveRecord::Migration[7.1]
  def change
    create_table :tickets do |t|
      t.string :ticket_to
      t.string :ticket_from
      t.string :description
      t.integer :cbc_amount
      t.integer :creator_id
      t.integer :rank
      t.integer :category_id

      t.timestamps
    end
  end
end
