class Membership < ActiveRecord::Base
  belongs_to :group
  belongs_to :person
  belongs_to :inviter, :class_name => "Person"
end
