class PeopleController < ApplicationController
  
  before_filter :ensure_client_login, :except => [:update_avatar, :get_avatar, :get_small_thumbnail, :get_large_thumbnail]
  before_filter :ensure_person_logout, :only  => :create
  #before_filter :fix_utf8_characters, :only => [:create, :update, :index]
  
  def index
    @people = Person.find_with_ferret(params['search'])
    @people_hash = @people.collect do |person|
      person.get_person_hash(@user)
    end
  end

  def show
    @person = Person.find_by_id(params['user_id'])
    if ! @person
      render :status => :not_found and return
    end
  end
  
  def create
    parameters_hash = HashWithIndifferentAccess.new(params.clone)
    params = fix_utf8_characters(parameters_hash) #fix nordic letters in person details
    
    @person = Person.new(params[:person])
    if @person.save
  
      @role = Role.new(:person_id => @person.id, 
                       :client_id => @client.id, 
                       :title => Role::USER, 
                       :terms_version => params[:person][:consent]
                      )
      @role.save
  
      if VALIDATE_EMAILS # set in conf/
        key = get_random_string
        @person.pending_validation = PendingValidation.new({:key =>  key})
        @person.pending_validation.save
        if VALIDATE_EMAILS && RAILS_ENV != "development"
          #address = confirmation_url({:key  => @person.pending_validation.key})
          #TODO Make above-like dynamic address creation to work
          #!campussourcing_2009-02-18.log:16:07:00 <@thierry> Gnomet: 
          #                 "#{request.protocol}#{request.host}#{request.request_uri}"
          #COULD BE ABOVE solution?? ^
          address = "http://cos.alpha.sizl.org/confirmation?key=#{@person.pending_validation.key}"
          UserMailer.deliver_registration_confirmation(@person, address)      
        end
      end
      # assosiating created user to current session
      # (this first login is allowed even though the mail is not yet confirmed)
      @application_session.person_id = @person.id
      @application_session.save
      
      render :status => :created and return
    else
      render :status => :bad_request, :json => @person.errors.full_messages.to_json 
      @person = nil
      return
    end
  end

  def update
    parameters_hash = HashWithIndifferentAccess.new(params.clone)
    params = fix_utf8_characters(parameters_hash) #fix nordic letters in person details
      
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
    
    render :status => :bad_request, :json => @person.errors.full_messages.to_json
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
   
    if params['sortBy'] == "status_changed"
      params['sortOrder'] ||= "ascending"
      @friends = @person.contacts.find(:all, :include => "person_spec")
      @friends.sort!{|a,b| sort_by_status_message_changed(a, b, params['sortOrder']) }
    else
      @friends = @person.contacts
    end
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
    fetch_avatar("full")
  end
  
  def get_small_thumbnail
    fetch_avatar("small_thumb")
  end
  
  def get_large_thumbnail
    fetch_avatar("large_thumb")
  end
  
  def update_avatar
    # COMMENTED AWAY TEMPORARILY TO HELP TESTING OF KASSI
    # if ! ensure_same_as_logged_person(params['user_id'])
    #   render :status => :forbidden and return
    # end
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
  
  def fetch_avatar(image_type)
    @person = Person.find_by_id(params['user_id'])
    if ! @person  
      render :status => :not_found and return
    end
    if @person.avatar
      case image_type
      when "full"
        @data = @person.avatar.raw_data
      when "large_thumb"
        @data = @person.avatar.raw_large_thumb
      when "small_thumb"
        @data = @person.avatar.raw_small_thumb   
      end
    else 
      get_default_avatar(@client, image_type)
    end           
    respond_to do |format|
      format.jpg
    end
  end
  
  def get_default_avatar(service, image_type)
    if service.nil?
      service_name = "cos"
    else
      service_name = service.name
    end
    full_filename = "#{RAILS_ROOT}/public/images/#{DEFAULT_AVATAR_IMAGES[service_name][image_type]}"
    @data = File.open(full_filename,'rb').read
  end  
  
  def sort_by_status_message_changed(a, b, sort_order)
    if a.person_spec.nil? || a.person_spec.status_message_changed.nil?
      order = -1
    elsif b.person_spec.nil? || b.person_spec.status_message_changed.nil?
      order = 1
    else
      order = a.person_spec.status_message_changed <=> b.person_spec.status_message_changed
    end
    if sort_order == "descending" #turn the order
      return order * -1
    else
      return order    #the default is "ascending"
    end
  end
end
