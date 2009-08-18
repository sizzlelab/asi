class Coreui::PrivacyController < ApplicationController
  layout "coreui"

  def index
    if @user
      redirect_to edit_coreui_privacy_path(:id => @user.id) and return
    else
      redirect_to coreui_root_path and return
    end
  end

  def show
    index
  end

  def edit
    if @user
      @rule = @user.profile_rule #TODO create profile rule if it's not there
      @rule_sets = @rule.to_hash_by_data
      @person = @user
    else
      flash[:warning] = "Please login to edit your profile privacy."
      redirect_to coreui_root_path and return
    end
  end

  def update
    @person = Person.find_by_id(params[:id])

    if @person.id != @user.id
      flash[:warning] = "You can only update your own privacy settings."
      redirect_to coreui_root_path and return
    end

    @rule = @person.profile_rule #TODO create profile rule if it's not there

    if @rule

      @rule_sets = @rule.to_hash_by_data
      params[:privacy].each do |field, setting|
        set = @rule_sets[field] #TODO create condition_action_set if it's not there
        if set
          condition = Condition.find_by_keyword(setting)
          set.condition = condition
          set.save
        end
      end

      flash[:notice] = "Privacy information updated."
    end
    redirect_to edit_coreui_privacy_path(:id => @user.id) and return
  end

end