class GroupsController < ApplicationController

  methods_not_requiring_person_login = [:show, :public_groups, :get_members]
  before_filter :ensure_person_login, :except => methods_not_requiring_person_login
  before_filter :ensure_client_login, :only => methods_not_requiring_person_login
  
  ADMIN_METHODS = [ :update, :accept_pending_membership_request, :get_pending_members, :change_admin_status ]
  before_filter :get_group_or_not_found, :only => [ :get_members, :show, :add_member, :remove_person_from_group, :update_membership_status ] + ADMIN_METHODS
  before_filter :ensure_admin, :only => ADMIN_METHODS

  def create
    parameters_hash = HashWithIndifferentAccess.new(params.clone)
    params = fix_utf8_characters(parameters_hash) #fix nordic letters in person details
    
    @group = Group.create(:title => params[:title], 
                          :group_type => params[:type],
                          :description => params[:description],
                          :created_by => @user)

    if @group.valid?
      render :status => :created and return
    else  
      render :status => :bad_request, :json => @group.errors.full_messages.to_json and return
    end
  end

  def show
    render :status => :forbidden, :json => "You are not allowed to view this group.".to_json and return unless @group.show?(@user)
  end
  
  def update
    if @group.update_attributes(params[:group])
      render :status => :ok, :json => @group.to_json
    else
      render :status => :bad_request, :json => @group.errors.full_messages.to_json
      @group = nil
    end
  end

  def public_groups
    @groups = Group.all_public
    @groups_hash = @groups.collect do |group|
      group.get_group_hash(@user)
    end
    render :template => 'groups/list_groups'
  end

  def add_member  
    if params[:user_id] != @user.id
      @invitee = Person.find_by_id(params[:user_id])
      @group.invite(@invitee, @user)
      render :status => :created, :json => "Invitation sent.".to_json and return
    end
    
    @person = Person.find_by_id(params[:user_id])
    if ! @person 
      render :status => :not_found, :json => ["Could not find a person with specified id"].to_json and return
    end

    if @person.is_member_of?(@group)
      render :status => :conflict, :json => "You are already a member of this group".to_json and return
    end

    if @group.group_type == 'open'
      @person.request_membership_of(@group)
      render :status => :ok, :json => "Become member of group succesfully.".to_json and return
    elsif @group.group_type == 'closed'
      @person.request_membership_of(@group)
      render :status => :ok, :json => "Membership requested.".to_json and return
    end

  end

  # Returns a list of the public groups of the person specified by user_id
  def get_groups_of_person
    #TODO match only public groups if asker is not the user himself.
    @groups = Person.find_by_id(params[:user_id]).groups
    @groups_hash = @groups.collect do |group|
      group.get_group_hash(@user)
    end
    render :template => 'groups/list_groups'
  end

  def get_members
    #TODO check that asker has rights to get info
    if @group
      @members = @group.members
    end
  end

  def update_membership_status
    
    if @user.is_admin_of?(@group)
      if !params[:admin_status].nil?
        result = change_admin_status
      end

      if params[:accepted]
        result = accept_pending_membership_request
      end
      render :status => result[:status], :json => result[:message].to_json and return
      
    else
      render :status => :forbidden, :json => "Changing admin status can be done by admins only.".to_json and return
    end
  end

  def remove_person_from_group
    if params[:user_id] != @user.id and not @user.is_admin_of?(@group)
      render :status => :forbidden, :json  => ["You are not authorized to remove this user from this group."].to_json and return
    end
    
    @person = Person.find_by_id(params[:user_id])
    if ! @person 
      render :status => :not_found, :json => ["Could not find a person with specified id"].to_json and return
    end
    
    @person.leave(@group)
    
    # If the last member leaves, the group is destroyed
    if @group.members.count < 1
      @group.destroy
    end
  end

  def get_pending_members
    @requests = @group.pending_members
  end

  def get_invites
    @groups = @user.invited_groups
    @groups_hash = @groups.collect do |group|
      group.get_group_hash(@user)
    end
    render :template => 'groups/list_groups'
  end

  private

  def get_group_or_not_found
    begin
      @group = Group.find(params[:group_id])
    rescue ActiveRecord::RecordNotFound
      render :status => :not_found, :json => "Group with id #{params[:group_id]} not found.".to_json
    end
  end


  def ensure_admin
    if not @user.is_admin_of?(@group)
      render :status => :forbidden, :json => "You are not an admin of this group.".to_json
    end
  end

  def accept_pending_membership_request
    person = Person.find_by_id(params[:user_id])

    if @user.accept_member(person, @group) 
      return {:status => :ok, :message => "Pending request accepted"}
    else
      return {:status => :unauthorized, :message => "Accepting pending requests can be done by admins only."}
    end

  end

  def change_admin_status
    person = Person.find_by_id(params[:user_id])

    if params[:admin_status]
      if @group.grant_admin_status_to(person)
        return {:status => :ok, :message => "Admin status granted."}
      end
    else
      if @user.id != person.id && @group.remove_admin_status_from(person)
        return {:status => :ok, :message => "Admin status removed."}
      end
    end

    return {:status => :forbidden, :message => "Request denied." }

  end

end

