class AvatarsController < ApplicationController

  cache_sweeper :people_sweeper, :only => [:update_avatar]

  ##
  # return_code:: 200 - OK
  # description:: Gets the full-sized avatar image of the user. If an avatar has not been set, a default avatar is returned.
  #               Maximum width is 600px and maximum height 800px.
  def show
    fetch_avatar("full")
  end

  ##
  # return_code:: 200 - OK
  # description:: Gets a thumbnail of the avatar of the user. Thumbnail dimensions are 50x50.
  def show_small_thumbnail
    expires_in 60.minutes, :public => true
    fetch_avatar("small_thumb")
  end

  ##
  # return_code:: 200 - OK
  # description:: Gets a thumbnail of the avatar of the user. Maximum thumbnail dimensions are 350x200.
  def show_large_thumbnail
    fetch_avatar("large_thumb")
  end

  ##
  # return_code:: 200 - OK
  # return_code:: 400 - The avatar is of an unsupported type. Supported types are <tt>image/jpeg</tt>, <tt>image/png</tt> and <tt>image/gif</tt>.
  # description:: Replaces this user's avatar. Each user is given an implicit default avatar at creation.<p>The semantics of this method are closer to that of <tt>PUT</tt> than <tt>POST</tt>. <tt>POST</tt> is used here due to the difficulty of multipart file uploads with the <tt>PUT</tt> method in some HTTP client libraries.
  # 
  # params::
  #   file:: The avatar picture file (as a multipart file upload).
  def update

    if ! ensure_same_as_logged_person(params['user_id'])
       render_json :status => :forbidden, :messages => "You must be logged as the owner of the profile to update avatar." and return
    end
    @person = Person.find_by_guid(params['user_id'])
    if ! @person
      render_json :status  => :not_found and return
    end
    if params[:file]
      [ :original_filename, :content_type ].each do |m|
        unless params[:file].respond_to?(m)
          render_json :status => :bad_request, :messages => "Malformed file upload" and return
        end
      end
      avatar = @person.create_avatar(:file => params[:file])
      if avatar.valid? and avatar.valid_image_data?
        render_json :status  => :ok and return
      else
        render_json :status  => :bad_request, :messages => avatar.errors.full_messages and return
      end
    else
      render_json :status  => :bad_request, :messages => "You did not provide a file." and return
    end
  end

  ##
  # return_code:: 200 - OK
  # description:: Deletes this user's avatar. <tt>GET</tt> will hereon return the default avatar.
  def delete
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

  def fetch_avatar(image_type)
    @person = Person.find_by_guid(params['user_id'])
    if ! @person
      render_json :status => :not_found and return
    end
    if @person.avatar && Rule.authorize?(@user, @person.id, "view", "avatar")
      case image_type
      when "full"
        @data = @person.avatar.raw_data
      when "large_thumb"
        @data = @person.avatar.raw_large_thumb
      when "small_thumb"
        @data = @person.avatar.raw_small_thumb
      end
      @filename = @person.avatar.filename
    else
      get_default_avatar(@client, image_type)
    end
    send_data(@data,
              :type => "image/jpeg",
              :filename => @filename,
              :disposition => 'inline')
  end

  def get_default_avatar(service, image_type)

    service_name = service.andand.name

    unless Image::DEFAULT_AVATAR_IMAGES[service_name]
      service_name = "cos"
    end

    full_filename = "#{Rails.root}/public/images/#{Image::DEFAULT_AVATAR_IMAGES[service_name][image_type]}"

    @data = File.open(full_filename,'rb').read
    @filename = "default-avatar.jpg"
  end

end
