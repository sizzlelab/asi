class Collection < ActiveRecord::Base
  usesguid

  has_many_polymorphs :items, :from => [:text_items, :binary_items], :through => :ownerships
  belongs_to :owner, :class_name => "Person"
  belongs_to :client

  def to_json(*a)
    {
      'id' => id,
      'entry' => items
    }.to_json(*a)
  end

  # Returns true if the given person, using the given client, is authorized to view this collection.
  def read?(person, client)
    if owner == nil
      return self.client == client
    end
    return (self.client == nil || self.client == client) && (owner == person || owner.contacts.include?(person))
  end

  # Returns true if the given person, using the given client, is authorized to change this collection.
  def write?(person, client)
    return read?(person, client) && (owner == person || ! read_only)
  end

  # Returns true if the given person, using the given client, is authorized to delete this collection.
  def delete?(person, client)
    return write?(person, client) && (owner == person)
  end

end
