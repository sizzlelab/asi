class PeopleController < ApplicationController
  
  before_filter :ensure_login, :except  => :create
  
  #TODO better checking for authorisation before making changes 
  # (also authorization for applications?)
  
  def index
     @people = Person.find(:all)
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
      render :status  => 200 and return
    else
      render :status => 500 and return
      # TODO Should return more informative message about what went wrong
    end
  end

  def update
    if ! check_authorization(params['user_id'])
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
    if ! check_authorization(params['user_id'])
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
    
    if ! check_authorization(params['user_id'])
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
    if ! check_authorization(params['user_id'])
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

  #Check that logged user is the same as the edited user
  def check_authorization(target_person_id)
    # if session[:session_id] == nil
    #   return false
    # end
    stored_session = Session.find_by_id(session[:session_id])
    return @user != nil && stored_session != nil && target_person_id == stored_session.person_id
  end
end
