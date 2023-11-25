class AddDefaultToRank < ActiveRecord::Migration[7.1]
  def change
    remove_column :tickets, :rank
    add_column :tickets, :rank, :integer, :default => 0
  end
end
