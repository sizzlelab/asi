class Collection < ActiveRecord::Base
  usesguid

  has_many_polymorphs :items, :from => [:text_items, :images], :through => :ownerships
  has_many :metadata, :class_name => "CollectionMetadataPair"
  belongs_to :owner, :class_name => "Person"
  belongs_to :client

  validates_presence_of :client

  def to_json(*a)
    {
      'id' => id,
      'entry' => items,
      'metadata' => metadata_hash
    }.to_json(*a)
  end

  def metadata_hash
    hash = Hash.new
    metadata.each do |pair|
      hash[pair.key] = pair.value
    end
    return hash
  end

  def metadata=(data)
    # XXX Does not delete overwritten keys (but this is not [functionally] a problem as the last one is always shown)
    data.each do |key, value|
      metadata << CollectionMetadataPair.new(:key => key, :value => value)
    end
  end

  # Returns true if the given person, using the given client, has permission to view this collection.
  def read?(person, client)
    if owner == nil
      return self.client == client
    end
     return (self.client == nil || self.client == client) && (owner == person || owner.contacts.include?(person))
  end

  # Returns true if the given person, using the given client, has permission to change this collection.
  def write?(person, client)
    return read?(person, client) && (owner == person || ! read_only)
  end

  # Returns true if the given person, using the given client, has permission to delete this collection.
  def delete?(person, client)
    return write?(person, client) && (owner == nil || owner == person)
  end

  # Attempts to create an item and add it to this collection.
  def create_item(options)
    #TODO Change the condition if file is not an image.
    #This didn't seem to work:
    #if options[:file].content_type.start_with?("image")
    if options[:file]    
      image = Image.new(:content_type => options[:file].content_type,
                        :filename => options[:filename], 
                        :data => options[:file].read)
      if image.valid_file? and image.successful_conversion?
        image.save
        items << image
        return true
      else 
        return false
      end    
    elsif options[:content_type].start_with?("text")
      text_item = TextItem.new(:text => options[:body])
      text_item.save
      items << text_item
      return true
    end
    return false
  end
end
