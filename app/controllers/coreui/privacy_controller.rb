class Coreui::PrivacyController < ApplicationController
  layout "coreui"

  def index
    if @user
      redirect_to edit_coreui_privacy_path(:id => @user.id) and return
    else
      redirect_to coreui_root_path and return
    end
  end

  def new
    redirect_to coreui_root_path and return
  end

  def create
    redirect_to coreui_root_path and return
  end

  def show
    id = @user ? @user.id : nil
    redirect_to edit_coreui_privacy_path(:id => id) and return
  end

  def edit
    if @user 
      @person = Person.find_by_id(@user.id)
    else
      flash[:warning] = "Please login to edit your profile privacy."
      redirect_to coreui_root_path and return
    end
  end

  def update
    @person = Person.find_by_id(params[:id])
    
    if @person.id != @user.id
      flash[:warning] = "You can only update your own privacy settings."
      redirect_to coreui_root_path and return
    end

    # TODO Create some privacy rules according to params
    
    params[:privacy].each do |field, setting|
      case setting # To change these values, see also coreui/privacy_helper.rb
      when "public"
        
      when "logged_in"
        
      when "friends_only"
        
      when "private"
        
      when "default"
        # Remove privacy rules for this profile field to revert to default setting?
      else
        # No changes (for example "custom")
      end
    end
    
    flash[:notice] = "Privacy information updated."
    redirect_to coreui_privacy_index_path and return
  end

  def destroy
  end

end
