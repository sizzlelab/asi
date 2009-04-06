class GroupsController < ApplicationController

  #TODO enable filters
  before_filter :ensure_person_login, :except => [:show, :public_groups]
  before_filter :ensure_client_login, :only => [:show, :public_groups]
  
  def create
    @group = Group.new(:title => params[:title], :group_type => params[:type], :description => params[:description])
    if @group.save
      # Make the creator as an admin member
      @user.become_member_of(@group)
      @group.grant_admin_status_to(@user)
      render :status => :created and return
    else  
      render :status => :bad_request, :json => @group.errors.full_messages.to_json and return
    end
  end

  def show
    #TODO check that asker has rights to get info
    
    #puts "show method! #{params[:group_id]}"
    @group = get_group_or_not_found(params[:group_id])

  end
  
  def public_groups
    #TODO match only public groups
    @groups = Group.all(:conditions => ["group_type = 'open' OR group_type = 'closed'"])
    render :template => 'groups/list_groups'
  end
  
  def add_member  
    #TODO check that people can add only himslef
    
    @group = Group.find_by_id(params[:group_id])
    @person = Person.find_by_id(params[:user_id])
    if ! @group
      render :status => :not_found, :json => "Could not find a group with specified id".to_json and return
    end
    if ! @person 
      render :status => :not_found, :json => "Could not find a person with specified id".to_json and return
    end
    
    @person.become_member_of(@group)   
  end
  
  # Returns a list of the public groups of the person specified by user_id
  def get_groups_of_person
    #TODO match only public groups
    @groups = Person.find_by_id(params[:user_id]).groups
    render :template => 'groups/list_groups'
  end
  
  def get_members
    #TODO check that asker has rights to get info
    
    @group = get_group_or_not_found(params[:group_id])
    @members = @group.members

  end
  
  private
  
  def get_group_or_not_found(group_id)
    group = Group.find_by_id(params[:group_id])
    if ! group
     render :status => :not_found, :json => "Could not find a group with specified id".to_json and return
    end
    return group
  end
end
