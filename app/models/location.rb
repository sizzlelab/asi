# == Schema Information
#
# Table name: locations
#
#  id         :integer(4)      not null, primary key
#  person_id  :integer(4)
#  latitude   :decimal(15, 12)
#  longitude  :decimal(15, 12)
#  label      :string(255)
#  created_at :datetime
#  updated_at :datetime
#  accuracy   :decimal(15, 3)
#

class Location < ActiveRecord::Base

  belongs_to :person

  attr_protected :created_at, :updated_at

  validates_numericality_of [:latitude, :longitude, :accuracy], :allow_nil => true
  validates_presence_of [:latitude, :longitude], :unless => :no_lat_long?

  validates_each :longitude, :allow_nil  => true do |record, attr, value|
     record.errors.add attr, 'is smaller than -180' if value < -180
     record.errors.add attr, 'is greather than 180' if value > 180
  end

  validates_each :latitude, :allow_nil  => true do |record, attr, value|
   record.errors.add attr, 'is smaller than -90' if value < -90
   record.errors.add attr, 'is greather than 90' if value > 90
  end

  # Return true if both latitude and longitude are missing
  def no_lat_long?
    !self.latitude && !self.longitude
  end

  def to_json(*a)
    as_json(*a).to_json(*a)
  end

  def as_json(*a)
    to_hash(*a)
  end

  def to_hash(*a)    
    {
      :latitude => self.latitude.to_f,
      :longitude => self.longitude.to_f,
      :label => self.label,
      :accuracy => self.accuracy,
      :updated_at => self.updated_at
    }
  end

  ##
  # return_code:: 200 - OK
  # description:: Lists elements of a list that are near the users current location.
  # params::
  #   user::	 @user
  #   client::	 @client
  #   elements:: List of elements that have a guid, can be iterated with .collect
  #              and have a to_hash function.
  #   guid::	 guid of the object to check the distance from
  #   limit::    Max amount of nearby elements to return, defaults to 50
  #   range::    Range that is considered 'near', defaults to 100km
  def self.get_near(user, client, elements, guid = nil, range = 100000, limit = 50)
    return nil if "#{APP_CONFIG.mestadb_host}".empty?
    @user = user
    @client = client
    guid = @user.guid if guid.nil?

    res = Location.get_list_locations(@user, @client, guid)
    return :status => "400", :messages => "Current user has no location data" if
      ActiveSupport::JSON.decode(res.body)["geojson"]["features"].empty? # res.nil?

    @location = ActiveSupport::JSON.decode(res.body)["geojson"]["features"][0]

    # TODO: Parameter to ignore the 1 hour limit?
    return :status => "400", :messages => "Location data is more than 1 hour old" if
      Time.parse(@location["properties"]["updated"]) < 1.hour.ago.utc

    list_csv = Location.create_csv(elements)
    return :status => "400", :messages => "No entities to satisfy the query" if
      list_csv.empty?
    # TODO: Filter returned entries with the mestadb 'last_modified_after' parameter?
    #       Probably use local check instead, check the optimize part of update_location
    res = get_list_near_locations(list_csv, range, limit)
    return :status => :bad_request, :messages => res.code if
      res.code != "200"

    list = create_hashlist(ActiveSupport::JSON.decode(res.body)["geojson"]["features"])
    return list
  end

  ##
  # description:: Creates csv list of element guids, only adding the objects that the user has right to see
  def self.create_csv(elements)
    list = Array.new

    elements.collect! { |element| 
      list << element.guid if Location.get_connection(element.guid)
    }

    list_csv = list.map {|element| "#{element}"}.join(',')
    return list_csv
  end

  ##
  # description:: Creates a user readable list, the elements can be mix of persons, messages, collections and binobjects.
  def self.create_hashlist(elements)
    list = Array.new
    elements.each do |entry|
      # NOTE: Probably better way to do this. :)
      entity = Person.find_by_guid(entry["guid"])
      entity = Message.find_by_guid(entry["guid"]) if entity.nil?
      entity = Collection.find_by_id(entry["guid"]) if entity.nil?
      entity = BinObject.find_by_guid(entry["guid"]) if entity.nil?
      list << entity.to_hash(@user, @client) unless entity.nil?
    end
    return list
  end

  ##
  # description:: Checks if the @user has rights to read an object. Needs @user and @client global variables.
  #               (these variables aren't inherited from controllers)
  def self.get_connection(element_id)
      return true if @user.class == Person && element_id == @user.guid

      entity = Person.find_by_guid(element_id)
      unless entity.nil?
        puts Connection.type(@user, entity)
        return Connection.exists?(@user, entity) 
      end
      entity = Collection.find_by_id(element_id)
      unless entity.nil?
        return entity.read?(@user,@client)
      end
      # entity = Message.find_by_guid(element_id)
      # NOTE: (Message controller 'index' calls models as_json without @user and @client)
      # NOTE: Message controller takes care of this
      #       Possibly add a check to ensure that user is on the same channel as message
      #       (Would enable quertung messages from outside message controller) 
      entity = BinObject.find_by_guid(element_id)
      unless entity.nil?
        return ensure_same_as_logged_person(entity.poster.guid)
      end
      return Rule.authorize?(@user, element_id, "view", "location")
      # NOTE: last line is pretty much same as using "return true" at this point.
   end 

  ##
  # description:: Returns the location of object/objects
  # params::
  #   user::	 @user
  #   client::	 @client
  #   list::     comma separated list of GUIDs
  def self.get_list_locations(user, client, list)
    # NOTE: Actually used as "get single object location", not _list_ locations..
    # TODO: Change name to get_location? :) and list -> guid
    return nil if "#{APP_CONFIG.mestadb_host}".empty?

    @user = user if @user.nil?
    @client = client if @client.nil?

    return nil unless Location.get_connection(list)
    
    url = URI.parse("http://#{APP_CONFIG.mestadb_host}:#{APP_CONFIG.mestadb_port}/api/?operation=entity_get&guid_list=#{list}")

    full_path = (url.query.blank?) ? url.path : "#{url.path}?#{url.query}"
    request = Net::HTTP::Get.new(full_path)

    res = Net::HTTP.start(url.host, url.port) { |http|
      http.request(request)
    }
    return res
  end

  ##
  # description:: Returns the location of object/objects
  # params::
  #   list::     comma separated list of GUIDs
  #   range::    maximum distance to the objects
  #   limit::    maximum amount of objects to return, starting from the nearest
  def self.get_list_near_locations(list, range, limit)
    # TODO: change to REST api http://api.rubyonrails.org/classes/ActiveResource/Base.html ?
    # XXX: If the list is over 8192B, apache might have problems understanding it
    #   TODO: Possibly change Location.get_near to cut the element lists to parts containing 100 guids each, then
    #         Get, and then combine results?
    #   NOTE: Might be able to use json 'data' field?
    url = URI.parse("http://#{APP_CONFIG.mestadb_host}:#{APP_CONFIG.mestadb_port}/api/?operation=entity_get&guid_list=#{list}&limit=#{limit}&range=#{range}&lat=#{@location["geometry"]["coordinates"][1]}&lon=#{@location["geometry"]["coordinates"][0]}")

    full_path = (url.query.blank?) ? url.path : "#{url.path}?#{url.query}"
    request = Net::HTTP::Get.new(full_path)

    res = Net::HTTP.start(url.host, url.port) { |http|
      http.request(request)
    }
    return res
  end

  ##
  # description:: Updates the location of a single object, identified by its guid
  # params::
  #   guid:: GUID of the object
  #   latitude:: 
  #   longitude::
  #   label:: label for the location (optional)
  def self.update_location(guid, latitude, longitude, label="")
    # OPTIMIZE:
    # We wouldn't need to query mestadb nearly as often if we'd save information if an object has locational data.
    # This could possibly be some location_updated_at kind of information. 
    # No other information would be needed, just guid - location_date pairs in a table.
    # Location is deleted -> drop that pair from the table etc so we'd know not to query mestadb for that users information.
    # The table would only contain guid - date pairs for the objects that actually have locational data.
    # Adding the pair would be based on the res.code information, if everything went fine on mestadb, the key should be there.
    # (At the moment we're querying mestadb for almost everything. That's really high overhead so I really suggest we change this)

    return nil if "#{APP_CONFIG.mestadb_host}".empty?

    res = Net::HTTP.post_form(URI.parse(
      "http://#{APP_CONFIG.mestadb_host}:#{APP_CONFIG.mestadb_port}/api/"),
      {'operation' => 'entity_post',
       'guid' => guid,
       'name' => label,
       'lat' => latitude,
       'lon' => longitude}
    )
    return res
  end

  ##
  # description:: Deletes the locational data from mestadb server
  def self.delete_location(guid)
    # XXX: Doesn't actually delete the data until delete_entity is added to mestadb
    # TODO: Change to mestadb delete command as soon as it's supported
    return nil if "#{APP_CONFIG.mestadb_host}".empty?
    res = Location.update_location(guid, 1, 1, " ")
    return res
  end


  ##
  # description:: Gets location of the current user and adds that location as the objects location
  #
  # params::
  #   user:: @user
  #   guid:: guid of the object
  #   time:: current users locational data must be newer than this for the object location to be added.
  def self.update_object_location(user, guid, time = 1.hour.ago.utc )
    return nil if "#{APP_CONFIG.mestadb_host}".empty?
    @user = user if @user.nil?
    res = get_list_locations(user, nil, @user.guid)
    if not res.body.empty?
      @location = ActiveSupport::JSON.decode(res.body)["geojson"]["features"][0]
      if time.nil? || Time.parse(@location["properties"]["updated"]) > time
        res = update_location(
          guid,
          @location["geometry"]["coordinates"][1],
          @location["geometry"]["coordinates"][0],
          @location["properties"]["name"]
        )
      end
    end
  end

end
