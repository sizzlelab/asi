class PeopleController < ApplicationController

  before_filter :change_me_to_userid
  before_filter :ensure_client_login, :except => [:update_avatar, :get_avatar, :get_small_thumbnail, :get_large_thumbnail, :reset_password, :change_password]
  before_filter :ensure_person_logout, :only  => [:create, :recover_password]
  before_filter :set_cache_control, :only => [:get_small_thumbnail, :get_large_thumbnail]

  cache_sweeper :people_sweeper, :only => [:create, :update, :delete, :update_avatar]

  PERSON_HASH_INCLUDES = [:address, :roles, :location, :avatar, :name]

=begin rapidoc
access:: Application
return_code:: 200 - OK
json:: {"entry":
[{"address":{"unstructured":"MyString, MyString MyString","street_address":"MyString","postal_code":"MyString","locality":"MyString"},"name":{"family_name":"Makkonen","unstructured":"Juho Makkonen","given_name":"Juho"},"birthdate":"1940-06-01","is_association":null,"username":"kusti","gender":{"displayvalue":"MALE","key":"MALE"},"avatar":{"status":"not_set","link":{"rel":"self","href":"\/people\/g1\/@avatar"}},"id":"g1","phone_number":"+358 40 834 7176","msn_nick":"maison","website":"http:\/\/example.com","description":"About me","irc_nick":"pelle","status":{"changed":"2008-08-28T10:58:12Z","message":"Valid person rocks."},"status_message":"Valid person rocks."}]
}

param:: search - The search term. Every user whose name matches the regular expression /.*search.*/ will be returned. However, all charactersin the search term are interpreted as literals rather than special regexp characters.

description:: Finds users based on their real names and usernames.
=end
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
      @people = Person.all(options)
      size = Rails.cache.fetch(Person.build_cache_key(:person_count, modified), :expires_in => 15.minutes) { Person.count }
    else
      query = (params['search'] || "").strip
      @people = Person.search("*#{query}*", :without => { :name_id => 0 },
                              :per_page => params[:per_page] ? params[:per_page].to_i : nil,
                              :page => params[:page] ? params[:page].to_i : nil)
      size = Rails.cache.fetch(Person.build_cache_key(:person_count, modified), :expires_in => 15.minutes) { @people.total_entries }
    end
    render_json :entry => @people.collect { |p| p.person_hash(@client, @user)  }, :size => size
  end

=begin rapidoc
access:: Client login
return_code:: 200 - OK
json:: { :entry => Factory.create_person }
description::  Gets the information of the user specified by user_id. Note that the timestamp for status_messages
latest update is always in UTC time. The 'avatar' slot in the returned JSON contains the link to the avatar
image and also the status of the avatar, which is 'set' or 'not_set' depending on if the user has uploaded an image or not.
=end
  def show
    if !(@person = Rails.cache.read(Person.build_cache_key(params['user_id'])) )
      @person = Person.find_by_guid(params['user_id'])
      if ! @person
        render_json :status => :not_found and return
      end
      Rails.cache.write(Person.build_cache_key(params['user_id']), @person, :expires_in => 60.minutes)
    end
    render_json :entry => @person.person_hash(@client.id, @user)
  end

=begin rapidoc
access:: Client login
return_code:: 201 - Created
return_code:: 400 - Bad request
return_code:: 409 - Conflict

json:: {"entry":
{"name":null,"status":{"changed":null,"message":null},"birthdate":null,"gender":{"displayvalue":null,"key":null},
"username":"teemu","phone_number":null,"is_association":null,"website":null,"id":"","description":null,
"avatar":{"status":"not_set","link":{"rel":"self","href":"\/people\/\/@avatar"}},
"msn_nick":null,"irc_nick":null,"status_message":null,"address":null}}

param:: person
  param:: username - The desired username. Must be unique in the system. Length 4-20 characters.
  param:: password - User's password.
  param:: email - User's email address.
  param:: is_association - 'true' if this user is an association. Associations may be displayed differently by applications, and they cannot send or receive friend requests.
  param:: consent - The version of the consent that the user has agreed to. For example: 'FI1'/'EN1.5'/'SE4'

description:: Creates a new user. If creation is succesful the current app-only session is changed to be associated also to the user that was just created.
=end
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

      render_json :status => :created, :entry => @person.person_hash(@client.id, @user)
    else
      render_json :status => :bad_request, :messages => @person.errors.full_messages
      @person = nil
      return
    end
  end

=begin rapidoc
access:: Self
return_code:: 200
return_code:: 400 - There's a problem with one of the parameters.
param:: person
  param:: password - A new password.
  param:: email - Person's email address
  param:: status_message - Person's current status message.
  param:: birthdate - Person's birthdate as date. Format yyyy-mm-dd
  param:: gender - Person's gender, either MALE or FEMALE.
  param:: description - A description of the person, or "about me".
  param:: website - A link to this person's website.
  param:: name
    param:: given_name - Person's given name.
    param:: family_name - Person's family name.
    param:: phone_number - Person's phone number, stored as a string.
  param:: address
    param:: street_address - Person's street address
    param:: postal_code - Person's postal code, e.g. 02150
    param:: locality - Person's locality, e.g. Espoo

description:: Update (or add) information to user's profile. The person-parameter needs to contain only the attributes that need to be changed. If an error occurs, both status code and an array of error messages are returned.
=end
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
        if @person.update_attributes(params[:person])
          render_json :entry => @person.person_hash(@client.id, @user) and return
        end
      rescue NoMethodError  => e
        errors = e.to_s
      end
    end

    render_json :status => :bad_request, :messages => @person.errors.full_messages
    @person = nil
  end

=begin rapidoc
access:: Self
return_code:: 200

description:: Deletes this user.
=end
  def delete
    @person = Person.find_by_guid(params['user_id'])
    if ! @person
      render_json :status => :not_found and return
    end
    if ! ensure_same_as_logged_person(params['user_id'])
      render_json :status => :forbidden and return
    end
    @person.destroy
    session[:cos_session_id] = @user = nil
    render_json :status => :ok
  end

=begin rapidoc
access:: Self
return_code:: 200
return_code:: 400 - If this user is an association.
param:: friend_id - The id of the friend being requested.

description:: Adds a new connection to this user. The connection is added as <em>pending</em> and changed to <em>accepted</em> after the friend accepts the request.
=end
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

=begin rapidoc
access:: Application
return_code:: 200
param:: email - The email address of the user.
description:: Sends a password recovery email to a specified email address.
=end
  def recover_password
    person = Person.find_by_email(params[:email])

    if person
      UserMailer.deliver_recovery(:key => CryptoHelper.encrypt("#{person.id}:#{person.salt}"),
                                  :email => person.email,
                                  :domain => SERVER_DOMAIN)
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
      person = Person.find(key[0], :conditions => {:salt => key[1]})

      if(params[:password] == params[:confirm_password])

        if person.update_attributes(:password => params[:password]);
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

=begin rapidoc
return_code:: 200

param:: sortBy - (Optional) A field according to which the results should be sorted. Currently only supported is status_changed that will sort the results based on the date of last status message change.
param:: sortOrder - (Optional) Valid values are ascending (default) and descending.
param:: per_page - Number of items to show.
param:: page - Page to show.

description:: Gets a list of this user's friends.
=end
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

=begin rapidoc
return_code:: 200

description:: Removes this friend connection.
=end
  def remove_friend
    return if !remove_any_connection_between(params['user_id'], params['friend_id'])
    render_json :status => :ok and return
  end


=begin rapidoc
return_code:: 200

description:: Returns a list of people who have requested to connect to this user.</p><p>A friend request is accepted by making the same request in the opposite direction.
=end
  def pending_friend_requests
    if ! ensure_same_as_logged_person(params['user_id'])
      render_json :status => :forbidden and return
    end
    render_json :entry => @user.pending_contacts
  end

=begin rapidoc
return_code:: 200

description:: Rejects this friend request.
=end
  def reject_friend_request
    if remove_any_connection_between(params['user_id'], params['friend_id'])
      render_json :entry => {}
    end
  end

=begin rapidoc
return_code:: 200
description:: Gets the full-sized avatar image of the user. If an avatar has not been set, a default avatar is returned. Maximum width is 600px and maximum height 800px.
=end
  def get_avatar
    fetch_avatar("full")
  end

=begin rapidoc
return_code:: 200
description:: Gets a thumbnail of the avatar of the user. Thumbnail dimensions are 50x50.
=end
  def get_small_thumbnail
    fetch_avatar("small_thumb")
  end

=begin rapidoc
return_code:: 200
description:: Gets a thumbnail of the avatar of the user. Maximum thumbnail dimensions are 350x200.
=end
  def get_large_thumbnail
    fetch_avatar("large_thumb")
  end

=begin rapidoc
return_code:: 200
return_code:: 400 - The avatar is of an unsupported type. Supported types are <tt>image/jpeg</tt>, <tt>image/png</tt> and <tt>image/gif</tt>

param:: file
  param:: content_type - Content type of user's avatar image.
  param:: filename - Filename of user's avatar image file.

description:: Replaces this user's avatar. Each user is given an implicit default avatar at creation.
=end
  def update_avatar

    if ! ensure_same_as_logged_person(params['user_id'])
       render :status => :forbidden and return
    end
    @person = Person.find_by_guid(params['user_id'])
    if ! @person
      render_json :status  => :not_found and return
    end
    if params[:file]
      avatar = @person.create_avatar(:file => params[:file])
      if avatar.valid?
        render_json :status  => :ok and return
      else
        render_json :status  => :bad_request, :messages => avatar.errors.full_messages and return
      end
    else
      render_json :status  => :bad_request, :messages => "You did not provide a file." and return
    end
  end

=begin rapidoc
return_code:: 200

description:: Deletes this user's avatar. <tt>GET</tt> will hereon return the default avatar.
=end
  def delete_avatar
    @person = Person.find_by_guid(params['user_id'])
    if ! @person
      render_json :status => :not_found and return
    end
    if ! @person.avatar
      render_json :status => :not_found and return
    end
    if ! ensure_same_as_logged_person(params['user_id'])
      render_json :status => :forbidden and return
    end
    @person.avatar.destroy
    render_json :status => :ok
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
    Connection.breakup(@person, @contact)
    return true
  end

  def fetch_avatar(image_type)
    @person = Person.find_by_guid(params['user_id'])
    if ! @person
      render_json :status => :not_found and return
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

    logger.debug service_name

    full_filename = "#{RAILS_ROOT}/public/images/#{DEFAULT_AVATAR_IMAGES[service_name][image_type]}"

    @data = File.open(full_filename,'rb').read
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

  def set_cache_control
    expires_in 60.minutes, :public => true
  end

  # If request is using /people/@me/xxxxxxx, change user_id from @me to real userid
  def change_me_to_userid
    if params[:user_id] == "@me"
      if ses = Session.find_by_id(session[:cos_session_id])
        if ses.person
          params[:user_id] = ses.person.guid
        else
          render_json :status => :unauthorized, :messages => "Please login as a user to continue" and return
        end
      end
    end
  end


end
