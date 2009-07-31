class LocationsController < ApplicationController

  before_filter :change_me_to_userid

  USER_UPDATEABLE_FIELDS = %w(longitude latitude accuracy label)

  before_filter :ensure_person_login, :only => :fetch_location_security_token
  #before_filter :ensure_client_login, :only => :update, #TODO Add this when SISSI is corrected

  def get
    @location = Person.find_by_guid(params['user_id']).location
    if ! @location
      #if location is not set, return just nils
      @location = Location.new
      @location.updated_at = nil
    end
  end

  def update

    # The logged user can change only her own location...
    if ! ensure_same_as_logged_person(params['user_id'])
      if !params['username'] and !params['password'] and !params['location_security_token']
        render :status => :forbidden and return
      end

      # ...unless the correct username and password is given
      # TODO: DEPRECATED, REMOVE WHEN SISSI IS MODIFIED
      if params['username'] or params['password']
        person = Person.find_by_username_and_password(params['username'], params['password'])
        if !person or (params['user_id'] && params['user_id'] != person.guid)
          render :status => :forbidden, :json => "Password and username didn't match the person.".to_json and return
        end
      end

      #...unless security token is given
      role = Role.find_by_location_security_token_and_client_id(params['location_security_token'], @client.id) if params['location_security_token']
      if !role and !person
        render :status => :forbidden and return
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
      render :status  => 406, :json => "Problem with parameters.".to_json and  return
      #TODO return more info about which parameter went wrong
    end
  end

  def fetch_location_security_token
    role = @user.roles.find_by_client_id(@client.id)
    render :status => :ok, :json => { :location_security_token => role.location_security_token }.to_json
  end

  private

  def change_me_to_userid
    if params[:user_id] == "@me"
      if ses = Session.find_by_id(session[:cos_session_id])
        if ses.person
          params[:user_id] = ses.person.guid
        else
          render :status => :unauthorized, :json => "Please login as a user to continue".to_json and return
        end
      end
    end
  end

end
