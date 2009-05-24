class Feedback < ActiveRecord::Base
  belongs_to :author, :class_name => "Person"
  
  validates_presence_of :content, :url
end
