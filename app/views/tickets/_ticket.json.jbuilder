json.extract! ticket, :id, :ticket_to, :ticket_from, :description, :cbc_amount, :creator_id, :rank, :category_id, :created_at, :updated_at
json.url ticket_url(ticket, format: :json)
