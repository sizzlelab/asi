class Coreui::ProfileController < ApplicationController
  layout "coreui"

  def index
    if @user
      @profile = Person.find_by_id(@user.id).get_person_hash(@user)
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
