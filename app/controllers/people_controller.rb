class PeopleController < ApplicationController
  
  before_filter :ensure_client_login 
  before_filter :ensure_person_logout, :only  => :create
    
  #TODO better checking for authorisation before making changes 
  # (also authorization for applications?)
  def index
    if params[:search]
      @people = Person.find_with_ferret(params[:search])
    else
      @people = Person.find(:all)
    end
  end

  def show
    @person = Person.find_by_id(params['user_id'])
    if ! @person
      render :status => 404 and return
    end
  end
  
  def get_by_username
    @person = Person.find_by_username(params['username'])
    if ! @person
      render :status  => 404 and return
    end
  end

  def create
    @person = Person.new(params[:person])
    if @person.save
      @session = @person.sessions.create
     session[:session_id] = @session.id
      #flash[:notice] = "Welcome #{@person.username}, you are now registered"
      render :status => 200 and return
    else
      render :status => 500 and return
      # TODO Should return more informative message about what went wrong
    end
  end

  def update
    if ! ensure_same_as_logged_person(params['user_id'])
      render :status => :forbidden and return
    end
    @person = Person.find_by_id(params['user_id'])
    if ! @person  
      render :status  => 404 and return
    end
    if @person.update_attributes(params[:person])
      #flash[:notice] = "Your account has been updated"
      render :status  => 200 and return
    else
      #render(:action => 'edit') #FROM AUTH
      render :status  => 500 and return
      #TODO return more info about what went wrong
    end
  end
  
  def delete
    @person = Person.find_by_id(params['user_id'])
    if ! @person  
      render :status => 404 and return
    end
    if ! ensure_same_as_logged_person(params['user_id'])
      render :status => :forbidden and return
    end
    @person.destroy
    session[:session_id] = @user = nil
  end
  
  def add_friend
    # If there is no pending connection between persons, 
    # add pendind/requested connections between them.
    # If there is already a pending connection requested from the other direction, 
    # change friendship status to accepted.
    
    if ! ensure_same_as_logged_person(params['user_id'])
      render :status => :forbidden and return
    end
    
    @person = Person.find_by_id(params['user_id'])
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
    if ! ensure_same_as_logged_person(params['user_id'])
      render :status => :forbidden and return
    end
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

end
