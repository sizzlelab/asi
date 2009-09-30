# == Schema Information
#
# Table name: feedbacks
#
#  id         :integer(4)      not null, primary key
#  content    :text
#  author_id  :string(255)
#  url        :string(255)
#  is_handled :integer(4)      default(0)
#  created_at :datetime
#  updated_at :datetime
#

class Feedback < ActiveRecord::Base
  belongs_to :author, :class_name => "Person"
  
  validates_presence_of :content, :url
end
