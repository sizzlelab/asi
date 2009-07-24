class SessionsController < ApplicationController

  before_filter :ensure_client_logout, :only => :create
  #skip_before_filter :maintain_session_and_user, :only => [:create]
  
  def get
    @session = @application_session
    if !@session
      render :status => :not_found and return
    end
  end
 
  def create
    # User Interface mode vs. API mode for return values.
    ui_mode = false
    
    if (params[:pt])
      params[:password] = params[:pt]
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
            render :status => :bad_request, :json => ["Both username and password are needed."].to_json
            return
          end
        end
    end
    if @session.save
      if (! @session.person_match) && (params[:username] || params[:password])
        # inserted username, password -pair is not found in database
        
        if (params[:pt]) # CAS Proxy Ticket
          conf = Hash.new()
          cas_logger = CASClient::Logger.new(RAILS_ROOT+'/log/cas.log')
          cas_logger.level = Logger::DEBUG
          conf[:cas_base_url] = CAS_BASE_URL
          conf[:validate_url] = conf[:cas_base_url] + '/proxyValidate'
          conf[:logger] = cas_logger
          cas_client = CASClient::Client.new(conf) 
          st = CASClient::ServiceTicket.new(params[:pt], "#{request.protocol}#{request.env['HTTP_HOST']}", false)
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
            flash[:warning] = "Password and username didn't match for any person."
            redirect_to :back and return
          else
            render :status => :unauthorized, :json => ["Password and username didn't match for any person."].to_json and return
          end
        end
      end
      
      if VALIDATE_EMAILS && PendingValidation.find_by_person_id(@session.person_id)
         @session.destroy
         if ui_mode
           flash[:warning] = "The email address for this user account is not yet confirmed. Logging in requires confirmation."
           redirect_to :back and return
         else
           render :status => :forbidden, :json => ["The email address for this user account is not yet confirmed. Login requires confirmation."].to_json and return
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
        render :status => :created, :json => { :user_id => @session.person_id,
                                               :app_id => @session.client_id }
      end
    else
      if ui_mode
        flash[:error] = @session.errors.full_messages
        redirect_to :back and return
      else
        render :status => :unauthorized, :json => @session.errors.full_messages.to_json and return
      end
    end
  
  end
 
  def destroy
    ui_mode = (@client && @client == Client.find_by_name(COREUI_APP_NAME))

    render :status => :not_found and return unless @application_session

    @application_session.destroy
    session[:cos_session_id] = @user = @client = nil

    if ui_mode
      flash[:notice] = "Successfully logged out."
      redirect_to coreui_root_path and return
    end

  end
  
end
