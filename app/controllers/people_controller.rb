class PeopleController < ApplicationController
  
  #TODO better checking for authorisation before making changes 
  # (also authorization for applications?)
  
  def index
     @people = Person.find(:all)
  end

  def show
   # Currently authorisation is not checked when viewing profile
   #TODO limit viewers to logged in users
    @person = Person.find_by_id(params['id'])
    if ! @person
      render :status => 404 and return
    end
  end
  
  def get_by_username
    #TODO limit viewers to logged in users
    @person = Person.find_by_username(params['username'])
    if ! @person
      render :status  => 404 and return
    end
  end

  def new #this method is from Auth-integration, can probably be removed
    @person = Person.new
  end

  def create
    @person = Person.new(params[:person])
    if @person.save
      @session = @person.sessions.create
      session[:id] = @session.id
      flash[:notice] = "Welcome #{@person.username}, you are now registered"
      #redirect_to(root_url) #FROM AUTH
      render :status  => 200 and return
    else
      render(:action => 'new') #FROM AUTH
      #render :status => 500 and return  #FROM AUTH this was the original before AUTH
    end
  end

  def edit #this method is from Auth-integration, can probably be removed
    @person = Person.find(@user)
  end

  def update
    if ! check_authorization
      render :status => :forbidden and return
    end
    @person = Person.find_by_id(params['id'])
    if ! @person  
      render :status  => 404 and return
    end
    if @person.update_attributes(params[:person])
      flash[:notice] = "Your account has been updated"
    else
      #render(:action => 'edit') #FROM AUTH
    end
  end
  
  def destroy # FROM AUTH 
    Person.destroy(@user)
    session[:id] = @user = nil
    flash[:notice] = "You are now unregistered"
    redirect_to(root_url)
  end
  
  #TODO DECIDE WHICH TO USE ^ destroy OR v DELETE ??
  
  def delete
    @person = Person.find_by_id(params['id'])
    if ! @person  
      render :status => 404 and return
    end
    if ! check_authorization
      render :status => :forbidden and return
    end
    @person.destroy
  end
  
  def add_friend
    # If there is no pending connection between persons, 
    # add pendind/requested connections between them.
    # If there is already a pending connection requested from the other direction, 
    # change friendship status to accepted.
    
    #TODO Authorization
    
    @person = Person.find_by_id(params['id'])
    if ! @person  
      render :status => 404 and return
    end
    @friend = Person.find_by_id(params['friend_id'])
    if ! @friend  
      render :status => 404 and return
    end
        
    if @person.requested_contacts.include?(@friend) #accept if requested
      Connection.accept(@person, @friend)
    else
      unless @person.pending_contacts.include?(@friend) || @person.contacts.include?(@friend)  
        Connection.request(@person, @friend)        #request if didn't exist
      end
    end
  end
  
  def get_friends
    @person = Person.find_by_id(params['user_id'])
    if ! @person  
      render :status => 404 and return
    end
    @friends = @person.contacts
  end
  
  def remove_friend
    @person = Person.find_by_id(params['user_id'])
    if ! @person  
      render :status => 404 and return
    end
    @friend = Person.find_by_id(params['friend_id'])
    if ! @friend  
      render :status => 404 and return
    end
    Connection.breakup(@person, @friend)
  end
  
  private
  #TODO Should make more options for authorisation

  def check_authorization
    return @user != nil && @user.id == params['id']
  end
end
