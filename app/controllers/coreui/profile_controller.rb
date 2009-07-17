class Coreui::ProfileController < ApplicationController
  layout "coreui"

  def index
    if @user 
      @person = Person.find_by_id(@user.id) # .get_person_hash(@user) 
    end
  end

  def new
  end

  def create
  end

  def show
  end

  def edit
  end

  def update
    person = Person.find_by_id(params[:id])
    
    # Merging person_spec from a separate hash to the "main hash"
    person_spec = params[:person][:person_spec]
    person_hash = params[:person].delete_if { |key, value| key == "person_spec" }
    person_hash.merge!(person_spec)
    
    person.update_attributes(person_hash)
    
    # TODO: Check for errors
    
    flash[:notice] = "Profile details updated."
    redirect_to coreui_profile_index_path and return
  end

  def destroy
  end

end
