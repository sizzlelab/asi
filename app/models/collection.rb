class Collection < ActiveRecord::Base
  usesguid

  has_many_polymorphs :items, :from => [:text_items, :images, :collections], :through => :ownerships, :as => :parent
  belongs_to :owner, :class_name => "Person"
  belongs_to :client
  serialize :metadata, Hash

  validates_presence_of :client

  def to_json(user=nil,client=nil,*a)
    return {}.to_json if client.nil?
    {
      'id' => id,
      'title' => title,
      'tags' => tags,
      'owner'  => owner_id,
      'entry' => get_items_array(user,client),
      'metadata' => metadata,
      'updated_at' => updated_at.utc,
      'updated_by' => updated_by,
      'read_only' => read_only,
      'indestructible' => indestructible
    }.to_json(*a)
  end

  def metadata=(data)
    old = read_attribute(:metadata) || Hash.new
    write_attribute(:metadata, old.merge(data)) unless data.nil?
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
    return write?(person, client) && (owner == nil || owner == person) && ! indestructible
  end

  # Attempts to create an item and add it to this collection.
  def create_item(options, person, client)
    if options[:file] && options[:file].content_type.start_with?("image")
      image = Image.new
      if (image.save_to_db?(options, person))
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
    elsif options[:content_type].start_with?("collection")
      if options[:collection_id].nil? ||
          (collection = Collection.find_by_id(options[:collection_id])) == nil ||
          ! collection.read?(person,client)
        return false
      end
      old_size = items.size
      items << collection
      return false if old_size == items.size #not add (probably because a duplicate)
      return true
    end
    return false
  end
  
  def delete_item(item_id)
    items.each do |item|
      if item.id == item_id
        item.destroy unless item.class == Collection
        items.delete(item)
      end
    end
  end
  
  def destroy
    items.each do |item|
      item.destroy unless item.class == Collection
    end
    super
  end
  
  # Returns a hash containing only the info about the collection, not the contents
  def link_hash
    { :id => id, :title => title, :tags  => tags, :updated_at => updated_at.utc,
      :updated_by => updated_by, :metadata => metadata,
      :link => {   :rel => "self", :href=> "/appdata/#{client.id}/@collections/#{id}"} 
    }
  end
  
  def set_update_info(time, updater)
    update_attributes({:updated_at => time, :updated_by => updater})
    
    #Check for parent collections and update them too
    parent_relations = Ownership.find :all, :conditions => ['item_id = ?', id]
    parent_relations.each do |parent_ref|
      parent = parent_ref.parent
      if parent.updated_at.utc + 2.seconds < time.utc
        puts "COMPARED #{parent.updated_at.utc + 2.seconds} AND #{time.utc}" 
        parent.set_update_info(time, updater)
      end
    end
    
    
  end
  
  private
  
  def get_items_array(user, client)
    items_array = []
    items.each do |item|
      if item.class == Collection
        items_array.push item.link_hash.merge({:type => "collection"}) if item.read?(user, client)
      else
        items_array.push item
      end
    end
    # Sort items by updated_at
    items_array.sort! {|a,b| sort_items(a,b)}
    return items_array
  end
  
  def sort_items(a,b)
    #logger.info { "type" + a[:type]+ "<--" }
    if a[:type] == "collection"
      if b[:type] == "collection"
        return -(DateTime.parse(a[:updated_at].to_s) <=> DateTime.parse(b[:updated_at].to_s)) 
      else
        return -1
      end
    else
      return 1
    end
  end
  
end
