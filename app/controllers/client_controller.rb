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
    render_json :entry => @people and return
  end
  
  def index_services
    if params['user_id']
      @services = Role.find_all_by_person_id(params['user_id'])
    end
    render_json :entry => @services and return
  end
  
  def create
    @role = Role.new(:person_id => params['user_id'], 
                    :client_id => params['app_id'], 
                    :title => params['title'], 
                    :terms_version => params['terms_version']
                   )
    if (@role.save)
      render_json :status => :created, :entry => @role and return
    else
      render_json :status => :bad_request, :messages => @role.errors.full_messages.to_json and return
    end
  end
  
  def show
    @role = Role.find_by_person_and_client_id(params['user_id'], params['app_id'])
    if ! @role
      render_json :status => :not_found, :entry => "No role found." and return
    end
    render_json :entry => @role and return
  end
  
  def update
    @role = Role.find_by_person_and_client_id(params['user_id'], params['app_id'])
    if ! @role
      render_json :status => :not_found, :messages => "No existing role found with specified user_id and app_id. Create one instead of updating." and return
    end
    
#    if Person.find_by_id(params['user_id'])
#      @role.person_id = params['user_id']
#    else
#      render_json :status => :bad_request, :messages => "No user found with the specified User ID." and return
#    end
#
#    if Client.find_by_id(params['app_id'])
#      @role.client_id = params['app_id']
#    else
#      render_json :status => :bad_request, :messages => "No client application found with the specified App ID." and return
#    end
    
    @role.title = params['role']['title']
    @role.terms_version = params['role']['terms_version']
    
    if @role.save
      render_json :entry => @role and return
    else
      render_json :status => :bad_request, :messages => @role.errors.full_messages.to_json and return
    end
  end
  
  def delete
    # TODO Should this also remove the user from client application's local database?
  end
  
end
