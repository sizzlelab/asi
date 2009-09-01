class LocationsController < ApplicationController

  before_filter :change_me_to_userid

  USER_UPDATEABLE_FIELDS = %w(longitude latitude accuracy label)

  before_filter :ensure_person_login, :only => :fetch_location_security_token
  #before_filter :ensure_client_login, :only => :update, #TODO Add this when SISSI is corrected

=begin rapidoc
return_code:: 200
json:: { :entry => Factory.create_location }
description:: Returns this person's location.
=end
  def get
    @location = Person.find_by_guid(params['user_id']).location
    if ! @location
      #if location is not set, return just nils
      @location = Location.new
      @location.updated_at = nil
    end
    render_json :entry => @location
  end

=begin rapidoc
param:: location_security_token - The current user's security token, obtained via <tt><%= link_to_api("@location_security_token") %></tt>
param::location
  param::latitude - Latitude coordinates in Decimal Degree format
  param::longitude - Longitude coordinate sin Decimal Degree format
  param::label - Text label given to current location
  param::accuracy - Accuracy of the location
description:: Sets the location of the user. If only some of the fields are updated, rest will be set to null.
=end
  def update

    # The logged user can change only their own location...
    if ! ensure_same_as_logged_person(params['user_id'])
      if !params['username'] and !params['password'] and !params['location_security_token']
        render_json :status => :forbidden and return
      end

      # ...unless the correct username and password is given
      # TODO: DEPRECATED, REMOVE WHEN SISSI IS MODIFIED
      if params['username'] or params['password']
        person = Person.find_by_username_and_password(params['username'], params['password'])
        if !person or (params['user_id'] && params['user_id'] != person.guid)
          render_json :status => :forbidden, :json => "Password and username didn't match the person.".to_json and return
        end
      end

      #...unless security token is given
      role = Role.find_by_location_security_token_and_client_id(params['location_security_token'], @client.id) if params['location_security_token']
      if !role and !person
        render_json :status => :forbidden and return
      end
    end

    user_id = params['user_id'] || role.person.guid unless person

    if !user_id
      user_id = person.guid
    end

    user = Person.find_by_guid(user_id)

    @location = user.location

    if ! @location
      @location = Location.new(:person => user)
      @location.save
    end

    if ! @location.update_attributes(params[:location])
      render_json :status  => 406, :json => "Problem with parameters.".to_json and  return
      #TODO return more info about which parameter went wrong
    end

    render_json :status => :ok
  end

=begin rapidoc
return_code:: 200

description:: The returned JSON has a field location_security_token which contains UUID string that can be used as a security token

json:: { :entry => { :location_security_token => UUID.timestamp_create.to_s } }
=end
  def fetch_location_security_token
    role = @user.roles.find_by_client_id(@client.id)
    render_json :status => :ok, :json => { :location_security_token => role.location_security_token }.to_json
  end

  private

  def change_me_to_userid
    if params[:user_id] == "@me"
      if ses = Session.find_by_id(session[:cos_session_id])
        if ses.person
          params[:user_id] = ses.person.guid
        else
          render_json :status => :unauthorized, :json => "Please login as a user to continue".to_json and return
        end
      end
    end
  end

end
