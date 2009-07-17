class LocationsController < ApplicationController

  before_filter :change_me_to_userid
  
  USER_UPDATEABLE_FIELDS = %w(longitude latitude accuracy label)

  # TODO: authorize
  def get
    @location = Location.find_by_person_id(params['user_id'])
    if ! @location
      #if location is not set, return just nils
      @location = Location.new
      @location.updated_at = nil
    end
  end

  def update
    # The logged user can change only her own location...
    if ! ensure_same_as_logged_person(params['user_id'])
      if !params['username'] or !params['password']
        render :status => :forbidden and return
      end

      # ...unless the correct username and password is given
      person = Person.find_by_username_and_password(params['username'], params['password'])
      if !person or (params['user_id'] && params['user_id'] != person.id)
        render :status => :unauthorized, :json => "Password and username didn't match the person.".to_json and return
      end
    end
    
    user_id = params['user_id']
    if !user_id
      user_id = person.id
    end
    
    @location = Location.find_by_person_id(user_id)
    
    if ! @location  
      @location = Location.new(:person_id => user_id)
      @location.save
    end

    new_values = {}
    USER_UPDATEABLE_FIELDS.each do |field|
      if params[field]
        new_values[field] = params[field]
      else
        new_values[field] = nil
      end
    end
    
    if ! @location.update_attributes(new_values)
      render :status  => 406, :json => "Problem with parameters.".to_json and  return
      #TODO return more info about which parameter went wrong
    end
  end
  
  private
  
  def change_me_to_userid
    if params[:user_id] == "@me"
      if ses = Session.find_by_id(session[:cos_session_id])
        if ses.person
          params[:user_id] = ses.person.id
        else
          render :status => :unauthorized, :json => "Please login as a user to continue".to_json and return
        end
      end
    end
  end


end
