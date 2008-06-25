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

  def create
    @person = Person.new(params[:user])
    #logger.info "Creating user: " + params[:user].inspect
    if @person.save
      render :status  => 200 and return
    else
      render :status => 500 and return
    end
  end

  def update
    if ! check_authorization
      render :status => :forbidden and return
    end
    @person = Person.find_by_id(params['id'])
    if ! @person  
      render :status  => 404 and return
    end
    @person.update_attributes(params[:person])
  end
  
  def delete
    if ! check_authorization
      render :status => :forbidden and return
    end
    @person = Person.find_by_id(params['id'])
    if ! @person  
      render :status => 404 and return
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
      unless @person.pending_contacts.include?(@friend) || @person.contacts.include?(@friend)  #request if didn't exist
        Connection.request(@person, @friend)
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
    if params['id'].to_i != session["user"]
      return false
    else
      return true
    end
  end
end
