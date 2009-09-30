class RulesController < ApplicationController
  layout "rules"
  before_filter :ensure_client_login

  def new
    if @user
      @person = Person.find_by_id(@user.id)

      @rule = Rule.new
      @rule.condition_action_sets.build

      @action = Action.find(:all)
      @condition = Condition.find(:all)
      @options = ""
      @condition.each do |condition|
        #determine the value for the selected option as "condition_type condition_value"
        @options = @options << "<option value='"+condition.condition_type+" "+condition.condition_value+"'>"
        #determine what will appear as an option
        if (condition.condition_type == "group") or (condition.condition_type == "user")
          @options = @options << condition.condition_type+" = "+condition.condition_value
        elsif (condition.condition_type == "logged_in") or (condition.condition_type == "is_friend")
          @options = @options << condition.condition_type
        else
          @options = @options << condition.condition_value
        end
        @options = @options << "</option>"
      end
    end
  end

  # create a new rule from create_rule view
  def create
    parameters_hash = HashWithIndifferentAccess.new(params.clone)
    params = fix_utf8_characters(parameters_hash) #fix nordic letters in person details
    @rule = Rule.new(params[:rule])
    @rule.state = "active"
    @rule.person_id = params[:user_id]
    # Get the action that was selected. We assume that exist just one action
    action = Action.find_by_action_type_and_action_value("view", params[:action_data])
    #get the conditions that are passed trough the select as an array with condition_type first and value next
    params[:condition].each do |field|
      teste = field.split(" ")
      condition = Condition.find_by_condition_type_and_condition_value(teste[0] , teste[1])
      #add the condition_action_set with the previous (only) action
      @rule.condition_action_sets.build(:condition_id => condition.id, :action_id => action.id)
    end
    if @rule.save
      flash[:notice] = "Successfully created rule."
      redirect_to rules_path
    else
      flash[:notice] = "Error."
      redirect_to :back
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
      flash[:notice] = "Rule was successfully updated."
    else
      flash[:notice] = "Rule wasn't updated."
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

end
