# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'logging_helper'
require 'json'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  layout 'default'

  around_filter :catch_no_method_errors

  before_filter :maintain_session_and_user

  after_filter :log
  after_filter :set_correct_content_type

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  #protect_from_forgery # :secret => '9c4bfc3f5c5b497cf9ce1b29fdea20f5'

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  filter_parameter_logging :password

  DEFAULT_AVATAR_IMAGES = {
    "cos" => {
      "full" => "cos_avatar_80_80.jpg",
      "large_thumb" => "kassi_avatar.png",
      "small_thumb" => "kassi_avatar_small.png"
    },
    "ossi" => {
      "full" => "cos_avatar_80_80.jpg",
      "large_thumb" => "cos_avatar_80_80.jpg",
      "small_thumb" => "cos_avatar_50_50.jpg"
    },
    "kassi" => {
      "full" => "kassi_avatar.png",
      "large_thumb" => "kassi_avatar.png",
      "small_thumb" => "kassi_avatar_small.png"
    }
  }

  def index
    render :layout => "doc"
  end

  def doc
    render :action => request.path[1..-1].gsub(/\/$/, ""), :layout => "doc"
  end

  def ensure_person_login
    unless @user
      render :status => :unauthorized, :json => "Please login as a user to continue".to_json and return
    end
  end

  def ensure_person_logout
    if @user
      render :status => :conflict, :json => "You must logout before you can login or register".to_json and return
    end
  end

  def ensure_client_login
    unless @client
      render :status => :unauthorized, :json => "Please login as a client to continue".to_json and return
    end
  end

  def ensure_client_logout
    if @client
      render :status => :conflict, :json => "You must logout client before you can login".to_json and return
    end
  end

  def ensure_same_as_logged_person(target_person_id)
    return @user && target_person_id == @user.id
  end

  def log
    CachedCosEvent.create do |e|
      e.user_id        = @user ? @user.id : nil
      e.application_id = @client ? @client.id : nil
      e.cos_session_id = session[:cos_session_id]
      e.ip_address     = request.remote_ip
      e.action         = controller_class_name + "\#" + action_name
      e.parameters     = filter_parameters(params).to_json
      e.return_value   = @_response.status
      e.headers        = request.headers.reject do |*a|
        a[0].starts_with?("rack") or a[0].starts_with?("action_controller")
      end.to_json
    end
  end

  def set_correct_content_type
    if params["format"]
      response.content_type = Mime::Type.lookup_by_extension(params["format"].to_s).to_s
    end
  end

  #this should be done to all stored params (from Kassi etc.) because Rails seems to mess up parsing utf8 charas encoded in \\u00e4 like form
  def fix_utf8_characters(parameter_hash)
    return HashWithIndifferentAccess.new(JSON.parse(parameter_hash.to_json.gsub(/\\\\u/,'\\u')))
  end

  def get_random_string
    chars_for_key = [('a'..'z'),('A'..'Z'),(0..9)].map{|i| i.to_a}.flatten
    return (0..10).map{ chars_for_key[rand(chars_for_key.length)]}.join
  end

  def ensure_channel_admin
    if @channel.channel_type == "group"
      if @channel.group_subscribers.size != 0 && ! @channel.group_subscribers[0].admins.exists?(@user)
        render :status => :forbidden and return
      end
    elsif !ensure_same_as_logged_person(@channel.owner_id)
      render :status => :forbidden and return
    end
  end

  def ensure_can_read_channel
    if !@channel.can_read?(@user)
      render :status => :forbidden and return
    end
  end

  def get_channel
    @channel = Channel.find_by_guid( params[:channel_id] )
    if !@channel
      render :status => :not_found and return
    end
  end

  protected

  def render_json(options = {})
    hash = Hash.new
    if options[:messages]
      hash[:messages] = [options[:messages]].flatten
      options.delete(:messages)
    end
    if options[:entry]
      hash[:entry] = options[:entry]
      options.delete(:entry)
    end
    if params[:per_page] && params[:page]
      hash[:pagination] = { :per_page => params[:per_page].to_i,
                            :page => params[:page].to_i
                          }
    end
    if options[:size]
      hash[:pagination][:size] = options[:size]
    end
    options[:json] = hash
    render options
  end

  def maintain_session_and_user
    if session[:cos_session_id]
      if @application_session = Session.find_by_id(session[:cos_session_id])
        @application_session.update_attributes(:ip_address => request.remote_addr, :path => request.path_info)
        @user = @application_session.person
        @client = @application_session.client
      else
        session[:cos_session_id] = nil
        render :status => :unauthorized and return
      end
    else
      #logger.debug "NO SESSION:" + session[:cos_session_id]
    end
  end

  #Feedback functionality
  # Change current navigation state based on array containing new navi items.
  def save_navi_state(navi_items)
    session[:navi1] = navi_items[0] || session[:navi1]
    session[:navi2] = navi_items[1] || session[:navi2]
    session[:navi3] = navi_items[2] || session[:navi3]
    session[:navi4] = navi_items[3] || session[:navi4]
    session[:profile_navi] = navi_items[4] || session[:profile_navi]
  end

  # Define how many listed items are shown per page.
  def per_page
    if params[:per_page].eql?("all")
      :all
    else
      params[:per_page] || 10
    end
  end

   # Feedback form is present in every view.
  def set_up_feedback_form
    @feedback = Feedback.new
  end

  def catch_no_method_errors
    begin
      yield
    rescue ActiveRecord::UnknownAttributeError => e
      render_json :status => :bad_request, :messages => "#{e.to_s}" and return
    rescue NoMethodError => e
      if e.name.to_s.end_with? "="
        render_json :status => :bad_request, :messages => "unknown attribute #{e.name.chop}" and return
      else
        render_json :status => :bad_request, :messages => "unknown attribute #{e.name}" and return
      end
    rescue ThinkingSphinx::ConnectionError => e
      render_json :status => 500, :messages => "The search daemon is dead." and return
    end
  end

end
