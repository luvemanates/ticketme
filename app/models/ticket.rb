WillPaginate.per_page = 5
class Ticket < ApplicationRecord
  has_and_belongs_to_many :users
  belongs_to :creator, :class_name => "User", :foreign_key => :creator_id
  has_many :ticket_comments
end
