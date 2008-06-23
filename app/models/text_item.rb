class TextItem < ActiveRecord::Base

  def to_json(*a)
    {
      :id => id,
      :type => "text/plain",
      :value => text
   }.to_json(*a)
  end

end
