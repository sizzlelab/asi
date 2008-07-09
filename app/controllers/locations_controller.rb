class LocationsController < ApplicationController
  def get
    
  end

  def update
    # The logged user can change only her own location
    if ! ensure_same_as_logged_person(params['user_id'])
      render :status => :forbidden and return
    end
    
  end

end
