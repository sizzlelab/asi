# == Schema Information
#
# Table name: text_items
#
#  id         :string(255)     default(""), not null, primary key
#  text       :text
#  created_at :datetime
#  updated_at :datetime
#

class TextItem < ActiveRecord::Base

  usesguid

  def to_json(*a)
    {
      :id => id,
      :type => "text/plain",
      :value => text
   }.to_json(*a)
  end

end
