class Ownership < ActiveRecord::Base
  belongs_to :parent, :class_name => "Collection", :foreign_key => "parent_id"
  belongs_to :item, :polymorphic => true
end
