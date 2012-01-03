class LocationsController < ApplicationController

  USER_UPDATEABLE_FIELDS = %w(longitude latitude accuracy label)

  before_filter :ensure_person_login, :only => :fetch_location_security_token
  before_filter :user_authorized?, :only => [:update , :destroy]
  #before_filter :ensure_client_login, :only => :update, #TODO Add this when SISSI is corrected

  ##
  # return_code:: 200
  # json:: { "entry" => { "guid" => "tmocBoArC993ONurh", "type" => "Feature", "geometry" => { "coordinates" => [50.0122, 60.22359], "type" => "Point"}, "Properties" => { "name" => "Alepa", "updated" => "20111002T170223" } } }
  # description:: Returns this person's location.
  def get
  # json:: { :entry => Factory.build(:location) }
    @person = Person.find_by_guid(params['user_id'])
    unless @person
      render_json :status => 404, :messages => "Person not found" and return
    end

    location = Location.get_list_locations(@user, @client, @person.guid)
    unless location.nil?
      location = JSON.parse(location.body)["geojson"]["features"][0]
    end
    render_json :status => 401, :entry => Array.new and return if location.nil?
    render_json :entry => location
  end

  ##
  # description:: Sets the location of the user. If only some of the fields are updated, rest will be set to null.
  #
  # params::
  #   location_security_token:: (optional) The current user's security token, obtained via <tt><%= link_to_api("@location_security_token") %></tt> If this parameter is submited, the location can be updated without being logged in as this user.
  #   location::
  #     latitude:: Latitude coordinates in Decimal Degree format
  #     longitude:: Longitude coordinate sin Decimal Degree format
  #     label:: Text label given to current location
  def update
    # XXX: "If only some of the fields are updated, rest will be set to null.", not anymore?
    # NOTE: Accuracy is not used anymore:      accuracy:: Accuracy of the location
    user_id = params['user_id'] || @role.person.guid unless @person

    if !user_id
      user_id = @person.guid
    end

    if params[:location][:latitude].nil? || params[:location][:longitude].nil?
      render_json :status  => 406, :json => "Problem with parameters.".to_json and  return
    end

    # user = Person.find_by_guid(user_id)
    # NOTE: not used

    res = Location.update_location(user_id, params[:location][:latitude], params[:location][:longitude], params[:location][:label])

#    # Mestadb queries can also be posted as json data..
#    data =  ActiveSupport::JSON.encode({'operation' => 'entity_post', 'guid' => user_id, 'lat' => @location.latitude, 'lon' => @location.longitude})
#    res = Net::HTTP.post_form(URI.parse("http://#{APP_CONFIG.mestadb_host}:#{APP_CONFIG.mestadb_port}/api/"),{'data' => data, 'operation' => 'entity_post'})

    render_json :status => :bad_request, :messages => "MestaDB returned code #{res.code}" and return if res.code != "200"
    render_json :status => :ok
  end

  ##
  # description:: Clears the location of a user.
  def destroy
    ui_mode = (@client && @client == Client.find_by_name(APP_CONFIG.coreui_app_name))
    
    user = Person.find_by_guid(params['user_id'])
    res = Location.delete_location(user.guid)

    if ui_mode
      redirect_to edit_coreui_profile_path(:id => user.id) and return
    end

    render_json :status => 400 if res.nil?
    render_json :status => :ok
  end

  
  ##
  # return_code:: 200
  # json:: { :entry => { :location_security_token => UUID.timestamp_create.to_s } }
  # description:: The returned JSON has a field location_security_token which contains UUID string that can be used as a security token
  def fetch_location_security_token
    role = @user.roles.find_by_client_id(@client.id)
    render_json :status => :ok, :json => { :location_security_token => role.location_security_token }.to_json
  end

private
# The logged user can change only their own location...
def user_authorized?
  if ! ensure_same_as_logged_person(params['user_id'])
      if !params['username'] and !params['password'] and !params['location_security_token']
        render_json :status => :forbidden and return
      end

      # ...unless the correct username and password is given
      # TODO: DEPRECATED, REMOVE WHEN SISSI IS MODIFIED
      if params['username'] or params['password']
        @person = Person.find_by_username_and_password(params['username'], params['password'])
        if !@person or (params['user_id'] && params['user_id'] != @person.guid)
          render_json :status => :forbidden, :json => "Password and username didn't match the person.".to_json and return
        end
      end

      #...unless security token is given
      @role = Role.find_by_location_security_token_and_client_id(params['location_security_token'], @client.id) if params['location_security_token']
      if !@role and !@person
        render_json :status => :forbidden and return
      end
    end
  end

end
