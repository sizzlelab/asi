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
    if params[:person][:password] != params[:person][:password2]
      flash[:error] = "Passwords didn't match."
      render :action => "link" and return
    end
    
    person = Person.new(:username => params[:person][:username], :password => params[:person][:password], :email => params[:person][:email])
    if !person.save
      flash[:error] = @person.errors.full_messages
      render :action => "link" and return
    end

    cas_credentials = Rails.cache.read(params[:guid]) if params[:guid]
    if cas_credentials
      person.authentication_service_links.create(:link => cas_credentials)
      redirect_to params[:redirect_uri]
    end
  end

  def link
    if params[:commit] == "No"
      @person = Person.new
    end
    @guid = params[:guid]
    @redirect_uri = params[:redirect_uri]
    @fallbac_uri = params[:fallback]
  end

  def question
    @guid = params[:guid]
    @redirect_uri = params[:redirect]
    @fallback_uri = params[:fallback]

    redirect_to params[:fallback] if !@guid
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
      @person.create_name if not @person.name
      @person.create_address if not @person.address
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
      flash[:error] = "Passwords didn't match."
      render :action => "edit" and return
    elsif !params[:person][:password] || params[:person][:password].empty?
      params[:person].delete :password
      params[:person].delete :password2
    end

    if params[:person][:gender].andand.empty?
      params[:person].delete :gender
    end

    if params[:file]
      avatar = @person.create_avatar(:file => params[:file])
      if not avatar.valid?
        flash[:error] = "Error with image upload."
        render :action => "edit" and return
      end
    end

    if @person.update_attributes(params[:person].except(:password2))
      flash[:notice] = "Profile information updated."
      redirect_to edit_coreui_profile_path and return
    else
      render :action => "edit" and return
    end
  end

  def destroy
  end

end
