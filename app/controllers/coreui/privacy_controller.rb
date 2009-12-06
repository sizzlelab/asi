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
      @rule = @user.profile_rule #TODO create profile rule if it's not there. It will be there cause is created at people_controller
      if not @rule
        Rule.create_default_profile_rule(@user)
        @rule = @user.profile_rule
      end
      @rule_sets = @rule.to_hash_by_data
      @person = @user
      if not @person.name
        @person.create_name
      end
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

    @rule = @person.profile_rule #TODO create profile rule if it's not there. The profile rule is already created at people_controller when a user is created.

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
