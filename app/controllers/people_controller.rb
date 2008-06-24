class PeopleController < ApplicationController
  
  #TODO better checking for authorisation before making changes 
  # (also authorization for applications?)
  
  def index
     @people = Person.find(:all)
  end

  def show
   # Currently authorisation is not checked when viewing profile
   #TODO limit viewers to logged in users
    begin
      @person = Person.find(params['id'])
    rescue ActiveRecord::RecordNotFound => e
      render :status => 404 and return
    end
  end
  
  def get_by_username
    #TODO limit viewers to logged in users
    begin
      @person = Person.find(params['username'])
    rescue ActiveRecord::RecordNotFound => e
      render :status  => 404 and return
    end
    
  end

  def create
    @person = Person.new(params[:user])
    logger.info "Creating user: " + params[:user].inspect
    if @person.save
      render :status  => 200 and return
    else
      render :status => 500 and return
    end
  end

  def update
    if ! check_authorization
      render :status => :forbidden and return
    end
    @person = Person.find(params['id'])
    @person.update_attributes(params[:person])
  end
  
  def delete
    if ! check_authorization
      render :status => :forbidden and return
    end
    begin
      @person = Person.find(params['id'])
    rescue ActiveRecord::RecordNotFound => e
      render :status => 404 and return
    end
     @person.destroy
  end
  
  def add_friend
    
    
  end
  
  def get_friends

  end
  
  def remove_friend
    
  end
  
  private
  #TODO Should make more options for authorisation

  def check_authorization
    if params['id'].to_i != session["user"]
      return false
    else
      return true
    end
  end
end
