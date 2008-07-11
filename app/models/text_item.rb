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
