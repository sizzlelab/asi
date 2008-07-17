class PeopleController < ApplicationController
  
  before_filter :ensure_client_login 
  before_filter :ensure_person_logout, :only  => :create

  def index
    @people = Person.find_with_ferret(params[:search])
  end

  def show
    @person = Person.find_by_id(params['user_id'])
    if ! @person
      render :status => :not_found and return
    end
  end
  
  def get_by_username
    @person = Person.find_by_username(params['username'])
    if ! @person
      render :status  => :not_found and return
    end
  end

  def create_
    @person = Person.new(params[:person])
    if @person.save
      @session = @person.sessions.create
      session[:session_id] = @session.id
      render :status => :created and return
    else
      render :status => :bad_request, :errors => @person.errors.full_messages.to_json and return
    end
  end

  def update
    if ! ensure_same_as_logged_person(params['user_id'])
      render :status => :forbidden and return
    end
    @person = Person.find_by_id(params['user_id'])
    if ! @person  
      render :status  => :not_found and return
    end
    if params[:person]
      if @person.update_attributes(params[:person])
        render :status => :ok and return  
      end
    end
    @person = nil
    render :status  => :bad_request, :errors => @person.errors.full_messages.to_json and return 
  end
  
  def delete
    @person = Person.find_by_id(params['user_id'])
    if ! @person  
      render :status => :not_found and return
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
      render :status => :not_found and return
    end
    @friend = Person.find_by_id(params['friend_id'])
    if ! @friend  
      render :status => :not_found and return
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
      render :status => :not_found and return
    end
    @friends = @person.contacts
  end
  
  def remove_friend
    if ! ensure_same_as_logged_person(params['user_id'])
      render :status => :forbidden and return
    end
    @person = Person.find_by_id(params['user_id'])
    if ! @person  
      render :status => :not_found and return
    end
    @friend = Person.find_by_id(params['friend_id'])
    if ! @friend  
      render :status => :not_found and return
    end
    Connection.breakup(@person, @friend)
  end
  
  def get_avatar
    @person = Person.find_by_id(params['user_id'])
    if ! @person  
      render :status => :not_found and return
    end
    @avatar = @person.avatar
  end
  
  def update_avatar
    if ! ensure_same_as_logged_person(params['user_id'])
      render :status => :forbidden and return
    end
    @person = Person.find_by_id(params['user_id'])
    if ! @person  
      render :status  => :not_found and return
    end
    if params[:file]
      if (@person.save_avatar?(params))
        render :status  => :ok and return
      else
        render :status  => :internal_server_error and return
      end  
    else
      render :status  => :bad_request and return
    end
  end
  
  def delete_avatar
    @person = Person.find_by_id(params['user_id'])
    if ! @person  
      render :status => :not_found and return
    end
    @person.avatar = Image.new
    if ! @person.avatar  
      render :status => :not_found and return
    end
    if ! ensure_same_as_logged_person(params['user_id'])
      render :status => :forbidden and return
    end
    @person.avatar.destroy
  end
  
end
