json.extract! user, :id, :email, :password, :display_name, :phone_number, :created_at, :update_at, :created_at, :updated_at
json.url user_url(user, format: :json)
