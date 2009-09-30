class Coreui::ProfileController < ApplicationController
  layout "coreui"

  def index
    if @user
      @person = Person.find_by_id(@user.id)
      @profile = Person.find_by_id(@user.id).person_hash(@user)
    end
  end

  def new
  end

  def create
  end

  def show
    if @user 
      @person = Person.find_by_id(@user.id)
      @profile = Person.find_by_id(@user.id).person_hash(@user)
    else
      flash[:warning] = "Please login to see the profile."
      redirect_to coreui_root_path and return
    end
  end

  def edit
    if @user 
      @person = Person.find_by_id(@user.id)
    else
      flash[:warning] = "Please login to edit the profile."
      redirect_to coreui_root_path and return
    end
  end

  def update
    @person = Person.find_by_id(params[:id])
    
    if @person.id != @user.id
      flash[:warning] = "You can only update your own profile."
      redirect_to coreui_root_path and return
    end
    
    if params[:person][:password] != params[:person][:password2]
      flash[:warning] = "Passwords didn't match."
      redirect_to :back and return
    end
    
    # Merging person_spec from a separate hash to the "main hash"
    person_spec = params[:person][:person_spec]
    person_hash = params[:person].delete_if { |key, value| key == "person_spec" || key == "password2" }
    person_hash.merge!(person_spec)
    logger.debug "Person_hash = #{person_hash.inspect}"

    @person.update_attributes(person_hash)
    
    flash[:notice] = "Profile information updated."
    redirect_to coreui_profile_index_path and return
  end

  def destroy
  end

end
