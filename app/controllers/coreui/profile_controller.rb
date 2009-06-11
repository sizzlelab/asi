class Coreui::ProfileController < ApplicationController
  layout "coreui"

  def index
    if @user && @client && Role.find_by_user_and_client_id(@user.id, @client.id) == Role::ADMINISTRATOR
      people = Person.find_with_ferret(params['search'])
      people_hash = people.collect do |person|
        person.get_person_hash(@user)
      end
      @profiles = people_hash
    elsif @user
      @profiles = Person.find_by_id(@user.id).get_person_hash(@user)
    else
      @profiles = nil
    end
  end

  def new
  end

  def create
  end

  def show
  end

  def edit
  end

  def update
  end

  def destroy
  end

end
