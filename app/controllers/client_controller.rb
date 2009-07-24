class ClientController < ApplicationController
  
  def index
    # TODO: now returns roles, would people be better?
    if params['roles']
      role = params['roles'].singularize
      @people = Role.find(:all, :conditions => {:client_id => params['app_id'], :title => role})
    elsif params['user_id']
      @people = Role.find_all_by_person_and_client_id(params['user_id'], params['app_id'])
    else
      @people = Role.find_all_by_client_id(params['app_id'])
    end
  end
  
  def index_services
    if params['user_id']
      @services = Role.find_all_by_person_id(params['user_id'])
    end
  end
  
  def create
    @role = Role.new(:person_id => params['user_id'], 
                    :client_id => params['app_id'], 
                    :title => params['title'], 
                    :terms_version => params['terms_version']
                   )
    if (@role.save)
      render :status => :created and return
    else
      render :status => :bad_request, :json => @role.errors.full_messages.to_json 
      @role = nil
      return
    end
  end
  
  def show
    @role = Role.find_by_person_and_client_id(params['user_id'], params['app_id'])
    if ! @role
      render :status => :not_found, :json => ["No role found."].to_json
    end
  end
  
  def update
    @role = Role.find_by_person_and_client_id(params['user_id'], params['app_id'])
    if ! @role
      render :status => :not_found, :json => ["No existing role found. Create one instead of updating."].to_json and return
    end
    
    if Person.find_by_id(params['user_id'])
      @role.person_id = params['user_id']
    else
      render :status => :bad_request, :json => ["No user found with the specified User ID."].to_json and return
    end

    if Client.find_by_id(params['app_id'])
      @role.client_id = params['app_id']
    else
      render :status => :bad_request, :json => ["No client application found with the specified App ID."].to_json and return
    end
    
    @role.title = params['title']
    @role.terms_version = params['terms_version']
    
    if @role.save
      render :status => :ok and return
    else
      render :status => :bad_request, :json => @role.errors.full_messages.to_json and return
    end
  end
  
  def delete
    # TODO Should this also remove the user from client application's local database?
  end
  
end
