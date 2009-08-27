class AvatarsController < ApplicationController

  before_filter :change_me_to_userid
  cache_sweeper :people_sweeper, :only => [:update_avatar]

=begin rapidoc
return_code:: 200
description:: Gets the full-sized avatar image of the user. If an avatar has not been set, a default avatar is returned. Maximum width is 600px and maximum height 800px.
=end
  def show
    fetch_avatar("full")
  end

=begin rapidoc
return_code:: 200
description:: Gets a thumbnail of the avatar of the user. Thumbnail dimensions are 50x50.
=end
  def show_small_thumbnail
    expires_in 60.minutes, :public => true
    fetch_avatar("small_thumb")
  end

=begin rapidoc
return_code:: 200
description:: Gets a thumbnail of the avatar of the user. Maximum thumbnail dimensions are 350x200.
=end
  def show_large_thumbnail
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
  def update

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
    if @person.avatar
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
    if service.nil?
      service_name = "cos"
    else
      service_name = service.name
    end

    logger.debug service_name

    full_filename = "#{RAILS_ROOT}/public/images/#{DEFAULT_AVATAR_IMAGES[service_name][image_type]}"

    @data = File.open(full_filename,'rb').read
    @filename = "default-avatar.jpg"
  end

end
