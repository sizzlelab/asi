# == Schema Information
#
# Table name: transactions
#
#  id          :integer(4)      not null, primary key
#  sender_id   :integer(4)
#  receiver_id :integer(4)
#  listing_id  :integer(4)
#  amount      :integer(4)
#  description :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

class Transaction < ActiveRecord::Base
   belongs_to :sender, :class_name => "Person", :foreign_key => "sender_id"
   belongs_to :receiver, :class_name => "Person", :foreign_key => "receiver_id"
     
   validates_presence_of :sender_id, :receiver_id, :amount
   
   validates_numericality_of :amount, :only_integer => true, :greater_than => 0, :allow_nil => true
end
