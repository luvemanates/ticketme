class AddFulltextIndex < ActiveRecord::Migration[7.1]
  def up
    execute "CREATE FULLTEXT INDEX fulltext_ticket ON tickets (ticket_to, ticket_from, description);"
  end
  def down
    execute "ALTER TABLE tickets DROP INDEX fulltext_ticket;"
  end
end
