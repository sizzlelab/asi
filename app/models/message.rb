class Message < ActiveRecord::Base
  
  belongs_to :poster, :class_name => "Person"
  belongs_to :channel

end
