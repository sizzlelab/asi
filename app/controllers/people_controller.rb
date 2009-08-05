class PeopleController < ApplicationController

  before_filter :change_me_to_userid
  before_filter :ensure_client_login, :except => [:update_avatar, :get_avatar, :get_small_thumbnail, :get_large_thumbnail, :reset_password, :change_password]
  before_filter :ensure_person_logout, :only  => [:create, :recover_password]
  #before_filter :fix_utf8_characters, :only => [:create, :update, :index]

=begin rapidoc
access:: Client login
return_code:: 200 - OK
json:: {"entry":
[{"name":{"given_name":"Tauno","unstructured":"Tauno Testilapio","family_name":"Testilapio"},
"status":{"message":"","changed":"2009-08-03T07:21:58Z"},
"birthdate":null,"gender":{"displayvalue":null,"key":null},
"role":null,"username":"testilapio","phone_number":"0501234567","is_association":null,
"website":null,"id":"b401CUzHur3R2baaWPEYjL","description":null,
"avatar":{"status":"not_set","link":{"rel":"self","href":"\/people\/106\/@avatar"}},
"msn_nick":null,"irc_nick":null,"status_message":"",
"address":{"postal_code":"02150","locality":"Espoo","
            unstructured":"Testaajankatu 1, 02150 Espoo","street_address":"Testaajankatu 1"}}]
}

param:: search - The search term. Every user whose name matches the regular expression /.*search.*/ will be returned. However, all charactersin the search term are interpreted as literals rather than special regexp characters.

description:: Finds users based on their (real) names.
=end
  def index
    if not params[:search]
      @people = Person.all
    else
      query = (params['search'] || "").strip
      @people = Person.search("*#{query}*", :without => { :name_id => 0 })
    end
    render_json :entry => @people.collect { |p| p.person_hash(@client, @user) }
  end

  def show
    @person = Person.find_by_guid(params['user_id'])
    if ! @person
      render :status => :not_found and return
    end
    render_json :entry => @person.person_hash(@client.id, @user)
  end

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

      render_json :status => :created, :entry => @person
    else
      render_json :status => :bad_request, :messages => @person.errors.full_messages
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
    @person = Person.find_by_guid(params['user_id'])
    if ! @person
      render :status => :not_found and return
    end
    if params[:person]
      begin
        if @person.update_attributes(params[:person])
          render_json :entry => @person and return
        end
      rescue NoMethodError  => e
        errors = e.to_s
      end
    end

    render_json :status => :bad_request, :messages => @person.errors.full_messages.to_json
    @person = nil
  end


  def delete
    @person = Person.find_by_guid(params['user_id'])
    if ! @person
      render :status => :not_found and return
    end
    if ! ensure_same_as_logged_person(params['user_id'])
      render :status => :forbidden and return
    end
    @person.destroy
    session[:cos_session_id] = @user = nil
  end


  def add_friend
    # If there is no pending connection between persons,
    # add pendind/requested connections between them.
    # If there is already a pending connection requested from the other direction,
    # change friendship status to accepted.

    if (params['user_id'] == params['friend_id'])
      render_json :messages => "Cannot add yourself to your friend.", :status => :bad_request
    end

    if ! ensure_same_as_logged_person(params['user_id'])
      render :status => :forbidden and return
    end

    @person = Person.find_by_guid(params['user_id'])
    if ! @person
      render :status => :not_found and return
    end
    @friend = Person.find_by_guid(params['friend_id'])
    if ! @friend
      render :status => :not_found and return
    end

    if @person.association? or @friend.association?
      render_json :messages => "Association users cannot have friends.".to_json, :status => :bad_request
    end

    if @person.pending_contacts.include?(@friend) #accept if pending
      Connection.accept(@person, @friend)
    else
      unless @person.requested_contacts.include?(@friend) || @person.contacts.include?(@friend)
        Connection.request(@person, @friend)        #request if didn't exist
      end
    end
  end

  def recover_password
    person = Person.find_by_email(params[:email])

    if person
      UserMailer.deliver_recovery(:key => CryptoHelper.encrypt("#{person.id}:#{person.salt}"),
                                  :email => person.email,
                                  :domain => SERVER_DOMAIN)
      render_json :messages => "Recovery mail sent to specified address.".to_json, :status => :ok and return
    else
      render_json :messages => "Record not found.".to_json, :status => :not_found and return
    end

  end

  def reset_password
    @id = params[:id];
  end

  def change_password
    if(!params[:id] || params[:id].empty?)
      flash[:notice] = "Access forbidden"
      render :status => :unauthorized and return
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
      render :status => :unauthorized and return
    end

  end

  def get_friends
    @person = Person.find_by_guid(params['user_id'])
    if ! @person
      render :status => :not_found and return
    end

    if params['sortBy'] == "status_changed"
      params['sortOrder'] ||= "ascending"
      @friends = @person.contacts.all
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
      render_json :status => :forbidden and return
    end
    render_json :entry => @user.pending_contacts
  end

  def reject_friend_request
    if remove_any_connection_between(params['user_id'], params['friend_id'])
      render :json => {}.to_json
    end
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
    @person = Person.find_by_guid(params['user_id'])
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
    @person = Person.find_by_guid(params['user_id'])
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

  # If request is using /people/@me/xxxxxxx, change user_id from @me to real userid
  def change_me_to_userid
    if params[:user_id] == "@me"
      if ses = Session.find_by_id(session[:cos_session_id])
        if ses.person
          params[:user_id] = ses.person.guid
        else
          render_json :status => :unauthorized, :messages => "Please login as a user to continue".to_json and return
        end
      end
    end
  end


end
