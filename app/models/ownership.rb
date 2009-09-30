# == Schema Information
#
# Table name: ownerships
#
#  id         :integer(4)      not null, primary key
#  parent_id  :string(255)
#  item_id    :string(255)
#  item_type  :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Ownership < ActiveRecord::Base
  belongs_to :parent, :class_name => "Collection", :foreign_key => "parent_id"
  belongs_to :item, :polymorphic => true
end
