class Collection < ActiveRecord::Base
  usesguid
  has_many_polymorphs :items, :from => [:text_items, :binary_items], :through => :ownerships
  belongs_to :owner, :class_name => "Person"
  belongs_to :client

  def to_json(*a)
    {
      'entry'         => items
    }.to_json(*a)
  end

end
