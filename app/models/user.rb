class User < ApplicationRecord
  has_and_belongs_to_many :tickets
  has_many :created_tickets, :class_name => 'Ticket', :foreign_key => :creator_id
end
