# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'logging_helper'

class ApplicationController < ActionController::Base
  protect_from_forgery

  helper :all
  layout 'default'

  before_filter :maintain_session_and_user
  before_filter :change_me_to_userid
  before_filter :change_app_to_appid

  after_filter :log, :except => [ :index, :doc ] if  APP_CONFIG.log_to_ressi

  PARAMETERS_NOT_TO_BE_ESCAPED = ["password", "confirm_password", "search", "query"]
  before_filter :escape_parameters

  def index
    render :layout => "doc"
  end

  def doc
    render :template => "application/#{request.path[1..-1].gsub(/\/$/, "")}", :layout => "doc"
  end

  if Rails.env.test?
    def test
      render :layout => "doc"
    end
  end

  def ensure_person_login
    unless @user
      status = (@client.andand.name == "ossi" ? :forbidden : :unauthorized)
      render_json :status => status, :messages => "Please login as a user to continue" and return
    end
  end

  def ensure_person_logout
    if @user
      render_json :status => :conflict, :messages => "You must logout before you can login or register" and return
    end
  end

  def ensure_client_login
    unless @client
      render_json :status => :unauthorized, :messages => "Please login as a client to continue" and return
    end
  end

  def ensure_client_logout
    if @client
      render_json :status => :conflict, :messages => "You must logout client before you can login" and return
    end
  end

  def ensure_same_as_logged_person(target_person_id)
    return @user && target_person_id == @user.guid
  end

  def escape_parameters
    params.each_pair do |key, value|
      unless PARAMETERS_NOT_TO_BE_ESCAPED.include? key
        params[key] = escape_html(value)
      end
    end
  end

  def log
    CachedCosEvent.create do |e|
      e.user_id           = @user ? @user.guid : nil
      e.application_id    = @client ? @client.id : nil
      e.cos_session_id    = session[:cos_session_id]
      e.ip_address        = request.remote_ip
      e.action            = controller_class_name + "\#" + action_name
      e.parameters        = filter_parameters(params).to_json
      e.return_value      = @_response.status
      e.semantic_event_id = params[:event_id]
      e.headers           = request.headers.reject do |*a|
        a[0].starts_with?("rack") or a[0].starts_with?("action_controller")
      end.to_json
    end
  end

  def get_random_string
    chars_for_key = [('a'..'z'),('A'..'Z'),(0..9)].map{|i| i.to_a}.flatten
    return (0..10).map{ chars_for_key[rand(chars_for_key.length)]}.join
  end

  def ensure_channel_admin
    if !ensure_same_as_logged_person(@channel.owner.guid)
      render :status => :forbidden and return
    elsif @channel.channel_type == "group"
      if @channel.group_subscribers.size != 0 && ! @channel.group_subscribers[0].admins.exists?(@user)
        render :status => :forbidden and return
      end
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
    if !options[:json]
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
        if options[:size]
          hash[:pagination][:size] = options[:size]
        end

      end
      options[:json] = hash
    end
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
      end
    end
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

  private

  def escape_html(value)
    return ActionView::Helpers::TagHelper.escape_once(value) if value.class == String
    return value if value.class != Array && value.class != Hash && value.class != HashWithIndifferentAccess

    if value.class == Array
      value.collect! do |v|
        escape_html v
      end
    elsif value.class == Hash || value.class == HashWithIndifferentAccess
      value.each_pair do |k, v|
        value[k] = escape_html(v)
      end
    end
  end

  protected

  def log_error(exception)
    super(exception)

    begin

      if Rails.env.production? && !APP_CONFIG.error_mailer_recipients.blank? 
        if APP_CONFIG.error_mailer_ignore_routing && exception.kind_of?(ActionController::RoutingError)
          return
        end
        ErrorMailer.snapshot(
          exception,
          clean_backtrace(exception),
          session,
          params,
          request,
          @user).deliver
      end
    rescue => e
      logger.error(e)
    end
  end

  private

  # If request is using /people/@me/xxxxxxx, change user_id from @me to real userid
  def change_me_to_userid
    if params[:user_id] == "@me"
      if @user
        params[:user_id] = @user.guid
      else
        render_json :status => :unauthorized, :messages => "Please login as a user to continue" and return
      end
    end
  end

  def change_app_to_appid
    if params[:app_id] == "@application"
      if @client
        params[:app_id] = @client.id
      else
        render_json :status => :unauthorized, :messages => "Please login as an application to continue" and return
      end
    end
  end

end
