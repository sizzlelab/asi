# -*- coding: utf-8 -*-
class GroupsController < ApplicationController

  methods_not_requiring_person_login = [:show, :public_groups, :get_members]
  before_filter :ensure_person_login, :except => methods_not_requiring_person_login
  before_filter :ensure_client_login, :only => methods_not_requiring_person_login

  ADMIN_METHODS = [ :update, :accept_pending_membership_request, :get_pending_members, :change_admin_status ]
  before_filter :get_group_or_not_found, :only => [ :get_members, :show, :add_member, :remove_person_from_group, :update_membership_status, :show_membership, :delete ] + ADMIN_METHODS
  before_filter :ensure_admin, :only => ADMIN_METHODS

=begin rapidoc
return_code:: 201
return_code:: 400 - There was an error in one or more parameters.
param:: group
  param:: title - The title (or name) of the group.
  param:: type - Can be open, closed, personal or hidden.
  param:: description - A descriptive text for the group (optional).
  param:: create_channel - If set to <tt>true</tt>, a channel for the group is also created with same name as group's title.
json:: { "entry" => Factory.create_example_group }
description:: Creates a new group. The creator is automatically added to the new group as an admin.
=end
  def create
    unless params[:group]
      render_json :status => :bad_request, :messages => "No group supplied. Note that params must be given as group[title] etc." and return
    end

    params[:group][:group_type] = params[:group][:type]
    params[:group].delete :type

    @group = Group.create(params[:group].merge({ :creator => @user }))

    if @group.valid?
      if params[:create_channel] == 'true' && params[:group][:group_type] != 'personal'
        @channel = Channel.create( :name => @group.title,
                                   :owner => @user,
                                   :channel_type => "group",
                                   :creator_app => @client)
        @channel.group_subscribers << @group
      end
      render_json :status => :created, :entry => @group and return
    else
      render_json :status => :bad_request, :messages => @group.errors.full_messages and return
    end
  end

=begin rapidoc
access:: Application
return_code:: 200
json:: { "entry" => Factory.create_example_group }
description:: Returns the details of this group.
=end
  def show
    unless @group.show?(@user)
      render_json :status => :forbidden, :messages => "You are not allowed to view this group." and return
    end
    render_json :entry => @group.get_group_hash(@user)
  end

=begin rapidoc
access:: Group admin
return_code:: 200
param:: group
  param:: title - The title (or name) of the group.
  param:: type - Can be open, closed or hidden.
  param:: description - A descriptive text for the group (optional).
json:: { "entry": Factory.create_example_group }
description:: Updates the information of this group. All parameters are optional; leave out the ones you do not wish to change. Personal groups cannot be changed to any other type and groups of other types cannot be changed to personal groups.
=end
  def update
    if @group.update_attributes(params[:group])
      render_json :entry => @group
    else
      render_json :status => :bad_request, :messages => @group.errors.full_messages
      @group = nil
    end
  end

=begin rapidoc
access:: Application
return_code:: 200
param:: query - A query to limit the group listing (optional). If this parameter is present, only groups whose title or description match the query are returned. The returned groups are sorted by relevance. Hidden groups that the possible logged-in user is a member of are present in the list.
param:: per_page - Number of entries to display.
param:: page - Page to display.
param:: sort_by - Field to sort results by. Defaults to <tt>updated_at</tt>. Possible values are <tt>created_at</tt>, <tt>updated_at</tt>, <tt>title</tt>, <tt>description</tt>, <tt>creator</tt>.
param:: sort_order - Possible values are <tt>ascending</tt> and <tt>descending</tt>. Defaults to <tt>descending</tt>.
json:: { "entry": [ Factory.create_group, Factory.create_group, Factory.create_group ] }
description:: Returns all the groups visible in the current session.
=end
  def public_groups
    groups = []
    options = {}
    if params[:query]
      groups = Group.search("*" + params[:query].strip + "*")
    else
      options[:conditions] = "group_type = 'open' OR group_type = 'closed'"
      options[:include] = :creator
      order_by = 'updated_at'
      order = 'DESC'
      if params[:sort_by] && %w{ updated_at created_at title creator description }.include?(params[:sort_by])
        order_by = params[:sort_by]
      end
      if params[:sort_order] == 'ascending'
        order = 'ASC'
      end
      options[:order] = order_by + " " + order
      groups = Group.all(options)
    end

    groups.filter_paginate!(params[:per_page], params[:page]) { |g| g.show?(@user) }

    @groups = groups.collect do |group|
      group.get_group_hash(@user)
    end
    render_json :entry => @groups, :size => groups.count_available and return
  end

=begin rapidoc
access:: User
return_code:: 200
param:: per_page - Number of entries to display.
param:: page - Page to display.
param:: sort_by - Field to sort results by. Defaults to <tt>updated_at</tt>. Possible values are <tt>created_at</tt>, <tt>updated_at</tt>, <tt>title</tt>, <tt>description</tt>.
param:: sort_order - Possible values are <tt>ascending</tt> and <tt>descending</tt>. Defaults to <tt>descending</tt>.
json:: { "entry": [ Factory.create_group, Factory.create_group, Factory.create_group ] }
description:: Returns all the personal groups of current user.
return_code:: 403 - The logged in user is different than <user_id>
=end 
  def personal_groups
    if !ensure_same_as_logged_person(params[:user_id])
      render_json :status => :forbidden, :messages => "A user's personal groups are only visible to that user." and return
    end
    options = {}
    options[:conditions] = {:group_type => 'personal', :creator_id => @user.id }
    options[:include] = :creator
    order_by = 'updated_at'
    order = 'DESC'
    if params[:sort_by] && %w{ updated_at created_at title description }.include?(params[:sort_by])
      order_by = params[:sort_by]
    end
    if params[:sort_order] == 'ascending'
      order = 'ASC'
    end
    options[:order] = order_by + " " + order
    @groups = Group.all(options)
    count = Group.count(options.slice(:conditions))
    render_json :entry => @groups, :size => count
  end

=begin rapidoc
return_code:: 201 - Succesfully deleted
return_code:: 403 - The logged in user is not the creator of this group or the group is not of type <tt>personal</tt>
access:: Group creator
param:: group_id - The id of target group.
description:: Deletes the group.
=end
  def delete
    if @group.group_type != "personal"
      render_json :status => :forbidden, :messages => "Not a personal group." and return
    end
    if !ensure_same_as_logged_person(@group.creator.guid)
      render_json :status => :forbidden, :messages => "Only group creator can delete personal groups." and return
    end
    @group.destroy
    render_json :status => :ok and return
  end

=begin rapidoc
return_code:: 201 - The join was successful.
return_code:: 202 - The invitation or membership request was sent.
return_code:: 403 - The logged in user is not allowed to send invitations to the group
return_code:: 409 - The user is already a member of the group or an invitation has already been sent.
param:: group_id - The id of the target group.
description::  Attempts to add the person specified by user_id to a group. This will succeed immediately if the group is open or user_id is logged in and has an invitation. If the group is closed and user_id is logged in, a membership request is sent. If user_id is not logged in, an invitation is sent to user_id – but only if the group is open or the logged in user is an admin of the group.
=end
  def add_member
    if @group.group_type == "personal"
      if !ensure_same_as_logged_person(@group.creator.guid)
        render_json :status => :forbidden, :messages => "Only personal group creator can add persons to group."
      end
      if !(@invitee = Person.find_by_guid(params[:user_id]))
        render_json :status => :not_found, :messages => "No person with spesified id found."
      end
      @group.accept_member(@invitee)
      render_json :status => :created and return
    end
    
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
    render_json :status => :ok and return
  end

=begin rapidoc
return_code:: 200
json:: { "entry": [

] }
description:: Returns the groups in which this user is a member.
=end
  def get_groups_of_person
    @groups = Person.find_by_guid(params[:user_id]).groups
    @groups_hash = @groups.find_all{|g| g.show?(@user)}.collect do |group|
      group.get_group_hash(@user)
    end
    render_json :entry => @groups and return
  end

=begin rapidoc
access:: Application
return_code:: 200
description:: Returns the member list of this group.
=end
  def get_members
    @members = @group.members
    @members.filter_paginate!(params[:per_page], params[:page]) { |r| true }
    @members.collect! { |p| p.to_hash(@user, @client) }
    size = @members.count_available
    render_json :entry => @members, :size => size and return
  end

=begin rapidoc
return_code:: 200
param:: accepted - True to accept a pending request.
param:: admin_status - True to grant admin rights, false to revoke them.
description:: Changes the membership status. User's admin status in group can be changed. Also, pending membership requests can be accepted. User's own admin status cannot be changed, changing of admin status must be done by different group admin.
=end
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

=begin rapidoc
return_code:: 200
description:: Removes this person from this group. Any user can remove their own membership. An admin user can remove any other user in the group (even other admins).
=end
  def remove_person_from_group
    if @group.group_type == "personal"
      if !ensure_same_as_logged_person(@group.creator.guid)
        render_json :status => :forbidden, :messages => "Only personal group's creator can remove members." and return
      end
    elsif params[:user_id] != @user.guid && !@user.is_admin_of?(@group)
      render_json :status => :forbidden, :messages  => "You are not authorized to remove this user from this group." and return
    end

    @person = Person.find_by_guid(params[:user_id])
    if ! @person
      render_json :status => :not_found, :messages => "Could not find a person with specified id" and return
    end

    @person.leave(@group)

    render_json :status => :ok
  end

=begin rapidoc
return_code:: 200
description:: Returns the pending members of this group. These are users that have requested membership of the group. See <%= link_to_api("/people/user_id/@groups/group_id/") %> to accept requests.
json:: { "entry": [

] }
=end
  def get_pending_members
    @requests = @group.pending_members - @group.invited_members
    render_json :entry => @requests
  end


=begin rapidoc
return_code:: 200
description:: Returns the groups this user has been invited to.
json:: { "entry": [

] }
=end
  def get_invites
    @groups = @user.invited_groups
    
    @groups_hash = @groups.collect do |group|
      group.get_group_hash(@user)
    end
    render_json :entry => @groups and return
  end

=begin rapidoc
return_code:: 200
return_code:: 403 - Only the authenticated person can view their membership status.
return_code:: 404 - The person or group doesn't exist or there is no connection between the two.

description:: Returns the membership status of this person in this group.
json:: { "entry" => Factory.create_group.memberships[0] }
=end
  def show_membership
    unless @person = Person.find_by_guid(params[:user_id])
      render_json :status => :not_found, :messages => "Person not found" and return
    end
    unless @person == @user
      render_json :status => :forbidden, :messages => "You can only view your own membership status" and return
    end
    unless @membership = @group.membership(@person)
      render_json :status => :not_found, :messages => "This person has no connection to this group" and return
    end    
    render_json :entry => @membership
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

end

