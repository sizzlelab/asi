class Collection < ActiveRecord::Base
  has_many :CollectionItems
  belongs_to :owner, :class_name => "Person"
end
