json.extract! ticket_comment, :id, :ticket_id, :user_id, :comment, :created_at, :updated_at
json.url ticket_comment_url(ticket_comment, format: :json)
