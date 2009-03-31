class GroupsController < ApplicationController

  def create
    @group = Group.new(:title => params[:title], :group_type => params[:type])
    if @group.save
      render :status => :created and return
    else  
      render :status => :bad_request, :json => @group.errors.full_messages.to_json and return
    end
  end

  def show
    #TODO check that asker has rights to get info
    
    #puts "show method! #{params[:group_id]}"
    @group = Group.find_by_id(params[:group_id])
    #@group = Group.find_by_id("testgroupid")
     if ! @group
       render :status => :not_found and return
     end
  end
  
  def public_groups
    #TODO match only public groups
    @groups = Group.find(:all)
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
  end
end
