class GroupsController < ApplicationController

  before_filter :change_me_to_userid, :except => [ :create, :public_groups, :show, :update, :get_members, :get_pending_members ]

  methods_not_requiring_person_login = [:show, :public_groups, :get_members]
  before_filter :ensure_person_login, :except => methods_not_requiring_person_login
  before_filter :ensure_client_login, :only => methods_not_requiring_person_login

  ADMIN_METHODS = [ :update, :accept_pending_membership_request, :get_pending_members, :change_admin_status ]
  before_filter :get_group_or_not_found, :only => [ :get_members, :show, :add_member, :remove_person_from_group, :update_membership_status ] + ADMIN_METHODS
  before_filter :ensure_admin, :only => ADMIN_METHODS

  def create
    parameters_hash = HashWithIndifferentAccess.new(params.clone)
    params = fix_utf8_characters(parameters_hash) #fix nordic letters in person details

    unless params[:group]
      render_json :status => :bad_request, :messages => "No group supplied. Note that params must be given as group[title] etc." and return
    end

    params[:group][:group_type] = params[:group][:type]
    params[:group].delete :type


    @group = Group.create(params[:group].merge({ :created_by => @user }))

    if @group.valid?
      if params[:create_channel]
        @channel = Channel.create( :name => @group.title,
                                :owner => @user,
                                :channel_type => "group",
                                :creator_app => @client)
      end
      render_json :status => :created, :entry => @group and return
    else
      render_json :status => :bad_request, :messages => @group.errors.full_messages.to_json and return
    end
  end

  def show
    unless @group.show?(@user)
      render_json :status => :forbidden, :messages => "You are not allowed to view this group." and return
    end
    render_json :entry => @group.get_group_hash(@user)
  end

  def update
    if @group.update_attributes(params[:group])
      render_json :entry => @group
    else
      render_json :status => :bad_request, :messages => @group.errors.full_messages.to_json
      @group = nil
    end
  end

  def public_groups
    groups = []

    if params[:query]
      groups = Group.search("*" + params[:query].strip + "*")
    else
      groups = Group.all_public
    end

    groups.filter_paginate!(params[:per_page], params[:page]) { |g| g.show?(@user) }

    @groups = groups.collect do |group|
      group.get_group_hash(@user)
    end
    render_json :entry => @groups, :size => groups.count_available and return
  end

  def add_member
    if params[:user_id] != @user.guid
      @invitee = Person.find_by_guid(params[:user_id])

      if @invitee.invited_groups.include?(@group)
        render_json :status => :conflict, :messages => "That user has already been invited." and return
      end

      if @group.invite(@invitee, @user)
        render_json :status => :accepted and return
      else
        render_json :status => :forbidden, :messages => "You are not an admin of this group." and return
      end
    end

    @person = Person.find_by_guid(params[:user_id])
    if ! @person
      render_json :status => :not_found, :messages => "Could not find a person with specified id" and return
    end

    if @person.is_member_of?(@group)
      render_json :status => :conflict, :messages => "You are already a member of this group" and return
    end

    if @group.group_type == 'open'
      @person.request_membership_of(@group)
      render_json :status => :created and return
    elsif @group.group_type == 'closed'
      @person.request_membership_of(@group)
      render_json :status => :accepted and return
    end

  end

  # Returns a list of the public groups of the person specified by user_id
  def get_groups_of_person
    @groups = Person.find_by_guid(params[:user_id]).groups
    @groups_hash = @groups.find_all{|g| g.show?(@user)}.collect do |group|
      group.get_group_hash(@user)
    end
    render :template => 'groups/list_groups'
  end

  def get_members
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
      render_json :status => result[:status], :messages => result[:message] and return

    else
      render_json :status => :forbidden, :messages => "Changing admin status can be done by admins only." and return
    end
  end

  def remove_person_from_group
    if params[:user_id] != @user.guid and not @user.is_admin_of?(@group)
      render_json :status => :forbidden, :messages  => "You are not authorized to remove this user from this group." and return
    end

    @person = Person.find_by_guid(params[:user_id])
    if ! @person
      render_json :status => :not_found, :messages => "Could not find a person with specified id" and return
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
      render_json :status => :not_found, :messages => "Group with id #{params[:group_id]} not found." and return
    end
    if ! @group.show?(@user)
      render_json :status => :forbidden, :messages => "You do not have permission to view this group."
    end
  end


  def ensure_admin
    if not @user.is_admin_of?(@group)
      render_json :status => :forbidden, :messages => "You are not an admin of this group."
    end
  end

  def accept_pending_membership_request
    person = Person.find_by_guid(params[:user_id])

    if @user.accept_member(person, @group)
      return {:status => :ok, :message => "Pending request accepted"}
    else
      return {:status => :unauthorized, :message => "Accepting pending requests can be done by admins only."}
    end

  end

  def change_admin_status
    person = Person.find_by_guid(params[:user_id])

    if params[:admin_status] and params[:admin_status].to_s.downcase != "false"
      if @group.grant_admin_status_to(person)
        return {:status => :ok, :message => "Admin status granted."}
      end
    else
      if @user != person && @group.remove_admin_status_from(person)
        return {:status => :ok, :message => "Admin status removed."}
      end
    end

    return {:status => :forbidden, :message => "Request denied." }

  end

  # If request is using /people/@me/xxxxxxx, change user_id from @me to real userid
  def change_me_to_userid
    if params[:user_id] == "@me"
      if ses = Session.find_by_id(session[:cos_session_id])
        if ses.person
          params[:user_id] = ses.person.id
        else
          render_json :status => :unauthorized, :messages => "Please login as a user to continue" and return
        end
      end
    end
  end

end

