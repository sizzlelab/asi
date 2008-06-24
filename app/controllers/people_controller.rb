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

  def create
    @person = Person.new
    @person.save
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
