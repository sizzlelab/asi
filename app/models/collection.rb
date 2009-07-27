class Collection < ActiveRecord::Base
  usesguid

  attr_accessor :user_set_id
  has_many_polymorphs :items, :from => [:text_items, :images, :collections], :through => :ownerships, :as => :parent
  belongs_to :owner, :class_name => "Person"
  belongs_to :client
  serialize :metadata, Hash

  validates_presence_of :client
  
  def initialize(params={})
    handle_user_requested_id_param(params[:id])
    super(params)
  end
  
  # GUID plugin sets its own random id automatically, but if user set an id, use it here
  def after_initialize
    if self.user_set_id
      self.id = self.user_set_id
    end
  end

  def to_hash(user=nil, client=nil, count=nil, start_index=nil, *a)
    return {} if client.nil?
    collection_data = basic_hash(user, client)
    
    collection_data.merge!(get_items_array(user, client, count, start_index))
    if !count.nil?
      collection_data.merge!({:itemsPerPage => count.to_i }) 
    end
    if !start_index.nil?
      collection_data.merge!({:startIndex => start_index.to_i})   
      else
      collection_data.merge!({:startIndex => 0})
    end
    return collection_data
  end

  # Returns a hash containing only the info about the collection, not the contents
  def info_hash(user, client)
    basic_info = basic_hash(user, client)
    basic_info.merge!({:totalResults => readable_items_count(user, client), 
                       :link => {   :rel => "self", :href => "/appdata/#{client.id}/@collections/#{id}"}
                       })
    return basic_info
  end
  
  # Returns a hash containing the basic info of the collection. Used for info_hash and coplete JSON
  def basic_hash(user, client)
    basic_hash = {
      :id => id,
      :title => title,
      :tags => tags,
      :owner  => owner_id,
      :priv => priv,
      :metadata => metadata,
      :updated_at => updated_at.utc,
      :updated_by => updated_by,
      :read_only => read_only,
      :indestructible => indestructible
    }
    updated_by_name = ""
    if ! updated_by.nil?
      if updater = Person.find_by_id(updated_by)
        updated_by_name = updater.name_or_username
      elsif updater = Client.find_by_id(updated_by)
        updated_by_name = updater.name
      end
    end
    
    basic_hash.merge!({:updated_by_name => updated_by_name})
    return basic_hash
  end

  def metadata=(data)
    old = read_attribute(:metadata) || Hash.new
    write_attribute(:metadata, old.merge(data)) unless data.nil?
  end

  # Returns true if the given person, using the given client, has permission to view this collection.
  def read?(person, client)
    if (! self.priv)
      return self.client == client
    end
    return (self.client == nil || self.client == client) && 
            (owner == person || owner.contacts.include?(person) || (!person.nil? && person.moderator?(client)))
  end

  # Returns true if the given person, using the given client, has permission to change this collection.
  def write?(person, client)
    return read?(person, client) && (owner == person || ! read_only || (!person.nil? && person.moderator?(client)))
  end

  # Returns true if the given person, using the given client, has permission to delete this collection.
  def delete?(person, client)
    return write?(person, client) && 
            (owner == nil || owner == person || (!person.nil? && person.moderator?(client))) && 
            ! indestructible
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
  
  def readable_items_count(user, client)
    items.select{|item| item.class != Collection || item.read?(user, client) }.size
  end
  
  def set_update_info(time, updater)
    update_attributes({:updated_at => time, :updated_by => updater})
    
    #Check for parent collections and update them too
    parent_relations = Ownership.find :all, :conditions => ['item_id = ?', id]
    parent_relations.each do |parent_ref|
      parent = parent_ref.parent
      #check that not already updated to avoind loops
      if parent.updated_at.utc + 2.seconds < time.utc
        parent.set_update_info(time, updater)
      end
    end
  end
  
  private
  
  def get_items_array(user, client, count, start_index)
    items_array = []
    items.each do |item|
      if item.class == Collection
        items_array.push item.info_hash(user, client).merge({:type => "collection"}) if item.read?(user, client)
      else
        items_array.push item
      end
    end
    # Sort items by updated_at
    items_array.sort! {|a,b| sort_items(a,b)}
    total_results = items_array.size
    
    # paginate results if requested
    if count
      count = count.to_i
      start_index ||= 1
      start_index = start_index.to_i
      start_index -= 1 #make indexing start from 0 (the first element)
      if count > items_array.size - start_index
        count = items_array.size - start_index
      end
      items_array = items_array[start_index..(start_index + count - 1)]
    end
    
    return {'entry' => items_array, 'totalResults' => total_results}
  end
  
  def sort_items(a,b)
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
  
  def handle_user_requested_id_param(id)
    #Check that if user submitted an id, it has to be in right format     
    if id 
      if  !(id =~ /^[A-Z0-9_]{8,22}$/i)
        errors.add :id, "is not in valid format. Use only letters, numbers and underscore. Length preferably 22. (min 8)"
      elsif Collection.find_by_id(id)
        errors.add(:id, "is already taken.")
      else
        self.user_set_id = id #store id from params to temporary attribute which is used in after_initialize        
      end   
    end 
  end  
end
