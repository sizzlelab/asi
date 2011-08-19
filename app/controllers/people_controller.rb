class PeopleController < ApplicationController

  before_filter :ensure_client_login, :except => [ :reset_password, :change_password ]
  before_filter :ensure_person_logout, :only  => [ :create, :recover_password ]

  cache_sweeper :people_sweeper, :only => [:create, :update, :delete ]

  PERSON_HASH_INCLUDES = [:address, :roles, :location, :avatar, :name]

  ##
  # access:: Application
  # return_code:: 200 - OK
  # json:: {"entry" => [ Factory.build(:person), Factory.build(:person) ] }
  # description:: Finds users based on their real names and usernames.
  #
  # params::
  #   search:: (optional) The search term. Every user whose name matches the regular expression /.*search.*/ will be returned.
  #            However, all charactersin the search term are interpreted as literals rather than special regexp characters.
  #   phone_number:: (optional) If this is entered (without search), returns only one person who has the exact same phone number stored
  #                  (358501234567 will match also +358501234567). This parameter is ignored if "search" parameter is submited.
  def index
    options = {:include => PERSON_HASH_INCLUDES}
    if params[:per_page]
      options[:limit] = params[:per_page].to_i
      if params[:page] && params[:page].to_i >= 1
        options[:offset] = params[:per_page].to_i * (params[:page].to_i-1)
      end
    end
    if not params[:search]
      modified = Rails.cache.fetch(Person.build_cache_key(:person_modified)) {
        Time.now
      }
      if params[:phone_number]
        @people = Person.find_by_phone_number(params[:phone_number])
        if @people.nil?
          # try again with + added in front of the number
          @people = Person.find_by_phone_number("+#{params[:phone_number]}")
        end
        @people = [@people] #wrap in an array as normal results
        
      else
        @people = Person.all(options)
        size = Rails.cache.fetch(Person.build_cache_key(:person_count, modified), :expires_in => 15.minutes) { Person.count }
      end
    else
      query = (params['search'] || "").strip
      @people = Person.search("*#{query}*", :without => { :name_id => 0 },
                              :per_page => params[:per_page] ? params[:per_page].to_i : nil,
                              :page => params[:page] ? params[:page].to_i : nil)
      size = @people.total_entries
    end
    
    render_json :entry => @people.compact.collect { |p| p.to_hash(@user, @client)  }, :size => size
  end

  ##
  # access:: Client login
  # return_code:: 200 - OK
  # json:: { :entry => Factory.build(:person) }
  # description::  Gets the information of the user specified by user_id. Note that the timestamp for status_messages latest update is always in UTC time.
  #                The 'avatar' slot in the returned JSON contains the link to the avatar image and also the status of the avatar, which is 'set' or 'not_set' depending on if the user has uploaded an image or not.
  def show

      @person = Person.find_by_guid(params['user_id'])
      if ! @person
        render_json :status => :not_found and return
      end
      Rails.cache.write(Person.build_cache_key(params['user_id']), @person, :expires_in => 60.minutes)

    render_json :entry => @person.to_hash(@user, @client)
  end

  ##
  # access:: Client login
  # return_code:: 201 - Created
  # return_code:: 400 - Bad request
  # return_code:: 409 - Conflict
  # json:: {"entry" => Factory.build(:person) }
  # description:: Creates a new user. If creation is succesful the current app-only session is changed to be associated also to the user that was just created.
  #               Also sends a welcoming email to the users email address.
  #
  # params::
  #   person::
  #     username:: The desired username. Must be unique in the system. Length 4-20 characters.
  #     password:: User's password.
  #     email:: User's email address.
  #     is_association:: 'true' if this user is an association. Associations may be displayed differently by applications, and they cannot send or receive friend requests.
  #     consent:: The version of the consent that the user has agreed to. For example: 'FI1'/'EN1.5'/'SE4'
  #   welcome_email:: Optional parameter. If false, no welcome email is sent. Default is true.
  def create
    @person = Person.new(params[:person])
    if @person.save
      @role = Role.new(:person => @person,
                       :client_id => @client.id,
                       :title => Role::USER,
                       :terms_version => params[:person][:consent])
      @role.save

      @application_session.person = @person
      @application_session.save

      unless params[:welcome_email] == "false"
        UserMailer.welcome(@person, @client).deliver
      end

      render_json :status => :created, :entry => @person.to_hash(@user, @client)
    else
      render_json :status => :bad_request, :messages => @person.errors.full_messages
      @person = nil
      return
    end
  end

  ##
  # access:: Self
  # return_code:: 200 - OK
  # return_code:: 400 - There's a problem with one of the parameters.
  # description:: Update (or add) information to user's profile. The person-parameter needs to contain only the attributes that need to be changed.
  #               If an error occurs, both status code and an array of error messages are returned.
  # 
  # params::
  #   person::
  #     password:: A new password.
  #     email:: Person's email address
  #     is_association:: Person's association status, 'true' or 'false'.
  #     status_message:: Person's current status message.
  #     birthdate:: Person's birthdate as date. Format yyyy-mm-dd
  #     gender:: Person's gender, either MALE or FEMALE.
  #     description:: A description of the person, or "about me".
  #     website:: A link to this person's website.
  #     phone_number:: Person's phone number, stored as a string.
  #     name::
  #       given_name:: Person's given name.
  #       family_name:: Person's family name.
  #     address::
  #       street_address:: Person's street address
  #       postal_code:: Person's postal code, e.g. 02150
  #       locality:: Person's locality, e.g. Espoo
  def update
    errors = {}
    if ! ensure_same_as_logged_person(params['user_id'])
      render_json :status => :forbidden and return
    end
    @person = Person.find_by_guid(params['user_id'])
    if ! @person
      render_json :status => :not_found and return
    end
    if params[:person]
      begin
        if @person.json_update_attributes(params[:person])
          render_json :entry => @person.to_hash(@user, @client) and return
        end
      rescue NoMethodError  => e
        errors = e.to_s
      end
    end

    render_json :status => :bad_request, :messages => @person.errors.full_messages
    @person = nil
  end

  ##
  # access:: Self
  # return_code:: 200 - OK
  # description:: Deletes this user.
  def delete
    @person = Person.find_by_guid(params['user_id'])
    if ! @person
      render_json :status => :not_found and return
    end
    if ! ensure_same_as_logged_person(params['user_id'])
      render_json :status => :forbidden and return
    end
    @person.destroy
    @application_session.destroy
    session[:cos_session_id] = nil
    render_json :status => :ok
  end

  ##
  # access:: Self
  # return_code:: 200 - OK
  # return_code:: 400 - If this user is an association.
  # description:: Adds a new connection to this user. The connection is added as <em>pending</em> and changed to <em>accepted</em> after the friend accepts the request.
  #
  # params::
  #   friend_id:: The id of the friend being requested.
  def add_friend
    # If there is no pending connection between persons,
    # add pendind/requested connections between them.
    # If there is already a pending connection requested from the other direction,
    # change friendship status to accepted.

    if (params['user_id'] == params['friend_id'])
      render_json :messages => "Cannot add yourself to your friend.", :status => :bad_request and return
    end

    if ! ensure_same_as_logged_person(params['user_id'])
      render_json :status => :forbidden and return
    end

    @person = Person.find_by_guid(params['user_id'])
    if ! @person
      render_json :status => :not_found and return
    end
    @friend = Person.find_by_guid(params['friend_id'])
    if ! @friend
      render_json :status => :not_found and return
    end

    if @person.association? or @friend.association?
      render_json :messages => "Association users cannot have friends.", :status => :bad_request and return
    end

    if @person.pending_contacts.include?(@friend) #accept if pending
      Connection.accept(@person, @friend)
    else
      unless @person.requested_contacts.include?(@friend) || @person.contacts.include?(@friend)
        Connection.request(@person, @friend)        #request if didn't exist
      end
    end

    render_json :status => :ok
  end

  ##
  # access:: Application
  # return_code:: 200 - OK
  # description:: Sends a password recovery email to a specified email address.
  #
  # params::
  #   email:: The email address of the user.
  def recover_password
    person = Person.find_by_email(params[:email])

    if person
      UserMailer.recovery(:key => CryptoHelper.encrypt("#{person.id}:#{person.salt}"),
                          :email => person.email,
                          :username => person.username,
                          :domain => APP_CONFIG.server_domain).deliver
      render_json :messages => "Recovery mail sent to specified address.", :status => :ok and return
    else
      render_json :messages => "Record not found.", :status => :not_found and return
    end

  end

  def reset_password
    @id = params[:id];
  end

  def change_password
    if(!params[:id] || params[:id].empty?)
      flash[:notice] = "Access forbidden"
      render_json :status => :unauthorized and return
    end

    begin
      key = CryptoHelper.decrypt(params[:id]).split(/:/);

      # use bang! version to throw ActiveRecord::RecordNotFound exception
      person = Person.find_by_id_and_salt!(key[0], key[1])

      if(params[:password] == params[:confirm_password])

        if person && person.update_attributes(:password => params[:password]);
          flash[:notice] = "Changed password successfully."
        else
          flash[:error] = person.errors.full_messages
          redirect_to "/people/reset_password?id=#{params[:id]}"
        end
      else
        flash[:error] = "Password and confirmation do not match."
        redirect_to "/people/reset_password?id=#{params[:id]}"
      end

    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "Access forbidden."
      render_json :status => :unauthorized and return
    end

  end

  ##
  # return_code:: 200 - OK
  # description:: Gets a list of this user's friends.
  # 
  # params::
  #   sortBy:: (Optional) A field according to which the results should be sorted.
  #            Currently only supported is status_changed that will sort the results based on the date of last status message change.
  #   sortOrder:: (Optional) Valid values are ascending (default) and descending.
  #   per_page:: Number of items to show.
  #   page:: Page to show.
  def get_friends
    @person = Person.find_by_guid(params['user_id'])
    if ! @person
      render_json :status => :not_found and return
    end

    if params['sortBy'] == "status_changed"
      params['sortOrder'] ||= "ascending"
      @friends = @person.contacts.all
      @friends.sort!{|a,b| sort_by_status_message_changed(a, b, params['sortOrder']) }
    else
      @friends = @person.contacts
    end
    @friends.filter_paginate!(params[:per_page], params[:page]){true}
    @friends.collect! { |p| p.to_hash(@user, @client)}
    render_json :entry => @friends, :size => @friends.count_available and return
  end

  ##
  # return_code:: 200 - OK
  # description:: Removes this friend connection.
  def remove_friend
    return if !remove_any_connection_between(params['user_id'], params['friend_id'])
    render_json :status => :ok and return
  end

  ##
  # return_code:: 200 - OK
  # description:: Returns a list of people who have requested to connect to this user.
  #               A friend request is accepted by making the same request in the opposite direction.
  def pending_friend_requests
    if ! ensure_same_as_logged_person(params['user_id'])
      render_json :status => :forbidden and return
    end
    render_json :entry => @user.pending_contacts
  end

  ##
  # return_code:: 200 - OK
  # description:: Rejects this friend request.
  def reject_friend_request
    if remove_any_connection_between(params['user_id'], params['friend_id'])
      render_json :entry => {}
    end
  end

  ##
  # access:: Application
  # return_code:: 200 - OK
  # json:: {"entry" => [ "email" => "unavailable", "username" => "available" ] }
  # description:: Checks if the username or email given in parameters are already in use in ASI.
  #
  # params::
  #   username:: returns unavailable, if this username is already in use, otherwise returns available.
  #   email:: returns unavailable, if this email is already in use, otherwise returns available.
  def availability
    resp = {}
    if params["username"]
      if Person.find_by_username(params["username"])
        resp["username"]  = "unavailable"
      else
        resp["username"] = "available"
      end
    end
    
    if params["email"]
      if Person.find_by_email(params["email"])
        resp["email"]  = "unavailable"
      else
        resp["email"] = "available"
      end
    end
    
    render_json :entry => [resp]
  end


  private

  def remove_any_connection_between(user_id, contact_id)
    if ! ensure_same_as_logged_person(user_id)
      render_json :status => :forbidden and return false
    end
    @person = Person.find_by_guid(user_id)
    if ! @person
      render_json :status => :not_found and return false
    end
    @contact = Person.find_by_guid(contact_id)
    if ! @contact
      render_json :status => :not_found and return false
    end
    if ! Connection.exists?(@person, @contact)
      render_json :status => :not_found, :messages => "#{contact_id} is not a friend of #{user_id}" and return false
    end
      Connection.breakup(@person, @contact)
    return true
  end


  def sort_by_status_message_changed(a, b, sort_order)
    if a.status_message_changed.nil?
      order = -1
    elsif b.status_message_changed.nil?
      order = 1
    else
      order = a.status_message_changed <=> b.status_message_changed
    end
    if sort_order == "descending" #turn the order
      return order * -1
    else
      return order    #the default is "ascending"
    end
  end

end
