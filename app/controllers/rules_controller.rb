class RulesController < ApplicationController
  layout "rules"
  before_filter :ensure_client_login, :except => [:create_default_profile_rule]

  PROFILE_FIELDS = %W(id username email name status_message birthdate phone_number gender irc_nick msn_nick avatar address location)

  def new
    @rule = Rule.new
    @rule.condition_action_sets.build
  end

  # create a new rule from create_rule view
  def create
    parameters_hash = HashWithIndifferentAccess.new(params.clone)
    params = fix_utf8_characters(parameters_hash) #fix nordic letters in person details
    @rule = Rule.new(params[:rule])
    @rule.state = "active"
    @rule.person_id = params[:user_id]

#    condition_id = Condition.find(:first, :conditions => { :condition_type => params[:condition_type], :condition_value => params[:condition_value] })

#    @rule.condition_action_sets.build(:condition_id => params[condition_id],
#                                       :action_id => params[:action_data])


    if @rule.save
      flash[:notice] = "Successfully created rule."
      redirect_to rules_path
    else
      flash[:notice] = "Error."
      redirect_to :back
    end
  end

  # put in controller only for test purposes
  # when a new user is created, a default profile rule with rule name "profile
  # rule"is automatically created for him.
  # The user can edit the profile rule later
  # default profile rule sets profile fieds username 'public', and all
  # the other fields "private"
  def create_default_profile_rule
    parameters_hash = HashWithIndifferentAccess.new(params.clone)
    params = fix_utf8_characters(parameters_hash) #fix nordic letters in person details

    @rule = Rule.new(:person_id => params[:user_id],
                    :rule_name => "profile rule",
                    :state => "active",
                    :logic => "and")
    
    # sets rule id as "person_id rule_name"
    # rule id cannot be set by "new", because id is protected attributes
    #@rule.id = params[:user_id] + " profile rule"
    # rule id is now generated automatically using 'usesguid' plugin
   
    # create condition_action_sets for this profile rule
    sets_hash = {}
    PROFILE_FIELDS.each do |field|
      if field == "username"
        sets_hash.merge!({field => "public"})
      else
        sets_hash.merge!({field => "private"})
      end
    end
    
    condition_public = Condition.find_by_condition_type_and_condition_value("publicity", "public")
    condition_private = Condition.find_by_condition_type_and_condition_value("publicity", "private")
    
    sets_hash.each_pair do |key, value|
      action = Action.find_by_action_type_and_action_value("view", key)
      if value == "public"
        condition_id = condition_public.id
      elsif value == "private"
        condition_id = condition_private.id
      end
      @rule.condition_action_sets.build(:condition_id => condition_id,
                                       :action_id => action.id)
    end
        
    if @rule.save
      flash[:notice] = "Default profile rule is created for user successfuly."
      redirect_to rules_path
    else
      flash[:notice] = "Default profile rule creation for user failed."
      redirect_to :back # not sure about this redirect_to
    end
  end

  # show all the rules belong to the user
  def index
    if @user
      @person = Person.find_by_id(@user.id)

      @rules = Rule.find_all_by_person_id(params[:user_id])
      @rules_hash = @rules.collect do |rule|
        rule.get_rule_hash(@user)
      end
    end
  end

  # show a rule
  # @condition_action_sets_hash = {action1=>conditions_array, action2=>conditions_array}
  def show
    if @user
      @person = Person.find_by_id(@user.id)
      @rule = Rule.find_by_id(params['id'])
      @condition_action_sets = @rule.get_condition_action_sets_belong_to_the_rule

      if ! @rule
        redirect_to rules_path
        flash[:notice] = "This rule doesn't exist."
      end
    end
  end

  #   update a rule, and associated conditon_action_sets
  def update
    @rule = Rule.find_by_id(params['id'])
    @rule.state = params['state']
    if @rule.update_attributes(params[:rule])
      flash[:notice] = 'Rule was successfully updated.'
    else
      flash[:notice] = 'Rule was successfully updated.'
    end
  end


  # distroy a rule and all the associated condition_action_sets
  def destroy
    @rule = Rule.find_by_id(params['id'])
    @rule.destroy
    if ! @rule
      render :status => :not_found and return
    end
    redirect_to rules_path
  end

  # enable a rule. set 'state' to 'active'
  def enable
    @rule = Rule.find_by_id(params['rule_id'])
    @rule.enable_rule
    redirect_to rules_path and return
  end

  # disable a rule. set 'state' to 'inactive'
  def disable
      @rule = Rule.find_by_id(params['rule_id'])
      @rule.disable_rule
      redirect_to rules_path and return
  end

  #  # get all the rules belong to a person
  #  def get_rules_of_person
  #    @rules = Rule.find_all_by_person_id(params[:user_id])
  #    @rules_hash = @rules.collect do |rule|
  #      rule.get_rule_hash(@user)
  #    end

  #    redirect_to coreui_profile_index_path
  #     render 'list_rules.erb'
  #    render :action => 'list_rules'
  #  end


end
