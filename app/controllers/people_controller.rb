class PeopleController < ApplicationController
  
  before_filter :ensure_client_login 
  before_filter :ensure_person_logout, :only  => :create
  #around_filter :catch_exceptions
  
  def index
    @people = Person.find_with_ferret(params['search'])
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

  def create
    @person = Person.new(params[:person])
    if @person.save
      @application_session.person_id = @person.id
      @application_session.save
      render :status => :created and return
    else
      render :status => :bad_request, :json => @person.errors.full_messages.to_json and return
    end
  end

  def update
    errors = {}
    if ! ensure_same_as_logged_person(params['user_id'])
      render :status => :forbidden and return
    end
    @person = Person.find_by_id(params['user_id'])
    if ! @person  
      render :status  => :not_found and return
    end
    if params[:person]
      begin
        if @person.update_attributes(params[:person])
          render :status => :ok and return
        end
      rescue NoMethodError  => e
        errors = e.to_s
      end
    end
   
    if @person.errors.full_messages.to_s == "Person spec is invalid"
      errors = @person.person_spec.errors.full_messages.to_json
    elsif ! @person.errors.full_messages.blank?
      errors = @person.errors.full_messages
    end
    
    render :status  => :bad_request, :json => errors.to_json
    @person = nil
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
    
    if (params['user_id'] == params['friend_id'])
      render :json => "Cannot add yourself to your friend.".to_json, :status => :bad_request
    end
    
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
        
    if @person.pending_contacts.include?(@friend) #accept if pending
      Connection.accept(@person, @friend)
    else
      unless @person.requested_contacts.include?(@friend) || @person.contacts.include?(@friend)  
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
    remove_any_connection_between(params['user_id'], params['friend_id'])
  end
  
  def pending_friend_requests
    if ! ensure_same_as_logged_person(params['user_id'])
      render :status => :forbidden and return
    end
    render :json => { :entry => @user.pending_contacts}.to_json
  end
  
  def reject_friend_request
    remove_any_connection_between(params['user_id'], params['friend_id'])
    render :json => {}.to_json
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
  
  private
  
  def remove_any_connection_between(user_id, contact_id)
    if ! ensure_same_as_logged_person(user_id)
      render :status => :forbidden and return
    end
    @person = Person.find_by_id(user_id)
    if ! @person  
      render :status => :not_found and return
    end
    @contact = Person.find_by_id(contact_id)
    if ! @contact  
      render :status => :not_found and return
    end
    Connection.breakup(@person, @contact)
  end
  
  # Catch NoMethodError
  # def catch_exceptions
  #   yield
  # rescue => NoSuchMethodException
  #   render :status  => :bad_request, :errors => @person.errors.full_messages.to_json and return
  # end
  
  
end
