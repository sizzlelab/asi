class Coreui::ProfileController < ApplicationController
  layout "coreui"

  def index
    if @user
      @person = Person.find_by_id(@user.id)
      @profile = Person.find_by_id(@user.id).to_hash(@user)
    end
  end

  def new
  end

  def create
  end

  def show
    if @user
      @person = Person.find_by_id(@user.id)
      @profile = Person.find_by_id(@user.id).to_hash(@user)
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

    if @person.update_attributes(params[:person].except(:password2, :password))
      flash[:notice] = "Profile information updated."
      redirect_to edit_coreui_profile_path and return
    else
      render :action => "edit" and return
    end
  end

  def destroy
  end

end
