class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email
      t.string :password
      t.string :display_name
      t.string :phone_number

      t.timestamps
    end
  end
end
