class LocationsController < ApplicationController
  
  USER_UPDATEABLE_FIELDS = %w(longitude latitude altitude vertical_accuracy horizontal_accuracy label)
  
  def get
    @location = Location.find_by_person_id(params['user_id'])
    if ! @location
      #if location is not set, return just nils
      @location = Location.new
      @location.updated_at = nil
    end
  end

  def update
    # The logged user can change only her own location
    if ! ensure_same_as_logged_person(params['user_id'])
      render :status => :forbidden and return
    end
    @location = Location.find_by_person_id(params['user_id'])
    if ! @location  
      @location = Location.new(:person_id => params['user_id'])
      @location.save
    end

    new_values = {}
    USER_UPDATEABLE_FIELDS.each do |field|
      new_values[field] = params[field] if params[field]
    end  
    
    if ! @location.update_attributes(new_values)
      puts @location.errors.inspect
      render :status  => 406 and return
      #TODO return more info about which parameter went wrong
    end
  end
end
