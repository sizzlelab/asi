class SessionsController < ApplicationController

  before_filter :ensure_client_logout, :only => :create
  #skip_before_filter :maintain_session_and_user, :only => [:create]

=begin rapidoc
access:: Free
return_code:: 200
description:: Returns the current session, if any.

json:: { "entry" :
  { "user_id" : "tmoCBomrl993MCurh",
    "app_id" : "aNfxPwHXmr3PkIacr-fEfL" } }
=end
  def get
    @session = @application_session
    render_json :status => :ok, :entry => @session and return
    if !@session
      render_json :status => :not_found and return
    end
  end

=begin rapidoc
access:: Free
return_code:: 201 - Successfully logged in.
return_code:: 403 - Invalid login details.
return_code:: 409 - A session already exists.
param:: session
  param:: app_name - The application's name.
  param:: app_password - The application's password.
  param:: username - The user's username (optional).
  param:: password - The user's password (optional).
  param:: proxy_ticket - A CAS proxy ticket (optional).

description:: Starts a new session. Sessions can be associated either
with an application only or with an application and a user. To start a session without logging a user in, provide no <tt>username</tt> or <tt>password</tt>.</p>
<p>Using HTTPS for logging in is recommended.

json:: { "entry" :
  { "user_id" : "tmoCBomrl993MCurh",
    "app_id" : "aNfxPwHXmr3PkIacr-fEfL" } }
=end
  def create

    if REQUIRE_SSL_LOGIN
      unless request.ssl? || local_request?
        redirect_to :protocol => "https://" and return
      end
    end

    # User Interface mode vs. API mode for return values.
    ui_mode = false


    if params[:app_name]
      render_json :status => :bad_request, :messages => "You are using a deprecated piece of API. See the changelog (/doc/changel/og) for details." and return
    end


    [ :app_name, :app_password, :username, :password, :proxy_ticket ].each do |param|
      params[param] = nil
      params[param] = params[:session][param] if params[:session] && params[:session][param]
    end


    if (params[:proxy_ticket])
      params[:password] = params[:proxy_ticket]
    end

    # TODO: Move from @session.save SASSI-version to model and create ticket-field to session.

    # If the right Rails authenticity_token is provided, we'll trust it's CoreUI
    if (params[:authenticity_token] && params[:authenticity_token] == form_authenticity_token && params[:app_name] == COREUI_APP_NAME)
      @session = Session.new({ :username => params[:username],
                               :password => params[:password],
                               :client_name => params[:app_name],
                               :client_password => COREUI_APP_PASSWORD })
      ui_mode = true
    else
      @session = Session.new({ :username => params[:username],
                               :password => params[:password],
                               :client_name => params[:app_name],
                               :client_password => params[:app_password] })
    end

    if (params[:username] || params[:password])
        # If other is present, both need to be
        unless (params[:username] && params[:password] )
          @session.destroy
          if ui_mode
            flash[:error] = "Both username and password are needed."
            redirect_to :back and return
          else
            render_json :status => :bad_request, :messages => "Both username and password are needed."
            return
          end
        end
    end
    if @session.save
      if (! @session.person_match) && (params[:username] || params[:password])
        # inserted username, password -pair is not found in database

        if (params[:proxy_ticket]) # CAS Proxy Ticket
          conf = Hash.new()
          cas_logger = CASClient::Logger.new(RAILS_ROOT+'/log/cas.log')
          cas_logger.level = Logger::DEBUG
          conf[:cas_base_url] = CAS_BASE_URL
          conf[:validate_url] = conf[:cas_base_url] + '/proxyValidate'
          conf[:logger] = cas_logger
          cas_client = CASClient::Client.new(conf)
          st = CASClient::ServiceTicket.new(params[:proxy_ticket], "#{request.protocol}#{request.env['HTTP_HOST']}", false)
          st_resp = cas_client.validate_proxy_ticket(st)

          if st_resp.is_valid?
            @session.person_match = Person.find_by_username(params[:username])
            @session.person_id = @session.person_match.id
            @session.save
          else
            @session.destroy
          end

        else
          @session.destroy
          if ui_mode
            flash[:warning] = "User login failed."
            redirect_to :back and return
          else
            render_json :status => :forbidden, :messages => "User login failed." and return
          end
        end
      end

      if VALIDATE_EMAILS && PendingValidation.find_by_person_id(@session.person_id)
         @session.destroy
         if ui_mode
           flash[:warning] = "The email address for this user account is not yet confirmed. Logging in requires confirmation."
           redirect_to :back and return
         else
           render_json :status => :forbidden, :messages => "The email address for this user account is not yet confirmed. Login requires confirmation." and return
         end
      end

      role = Role.find_by_person_and_client_id(@session.person_id, @session.client_id)
      if ! role
        # First time using this service, so let's create a Role with default parameters
        Role.create(:person_id => @session.person_id,
                    :client_id => @session.client_id,
                    :title => Role::USER
                   )
      end

      session[:cos_session_id] = @session.id
      if ui_mode
        flash[:notice] = "Logged in."
        redirect_to coreui_profile_index_path and return
      else
        render_json :status => :created, :entry => { :user_id => @session.person.andand.guid,
                                                     :app_id => @session.client_id }
      end
    else
      if ui_mode
        flash[:error] = @session.errors.full_messages
        redirect_to :back and return
      else
        render_json :status => :forbidden, :messages => @session.errors.full_messages and return
      end
    end

  end

=begin rapidoc
return_code:: 200
description:: Ends the current session.
=end
  def destroy
    ui_mode = (@client && @client == Client.find_by_name(COREUI_APP_NAME))

    render_json :status => :not_found and return unless @application_session

    @application_session.destroy
    session[:cos_session_id] = @user = @client = nil

    render_json :status => :ok

    if ui_mode
      flash[:notice] = "Successfully logged out."
      redirect_to coreui_root_path and return
    end

  end

end
