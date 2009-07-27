class RulesController < ApplicationController

  before_filter :ensure_client_login
  
  # create a new rule
  def create
    parameters_hash = HashWithIndifferentAccess.new(params.clone)
    params = fix_utf8_characters(parameters_hash) #fix nordic letters in person details

    @rule = Rule.create(:person_id => @user,

      :rule_name => params[:rule_name],
                          :state => params[:state],
                          :logic => params[:logic])

    if @rule.valid?
      render :status => :created and return
    else
      render :status => :bad_request, :json => @rule.errors.full_messages.to_json and return
    end
  end

  # show a rule
  def show
    
  end

  # update a rule
  def update

  end

  # get all the rules belong to a person
  def get_rules_of_person
    @rules = Rule.find_by_id(params[:user_id]).rules
    @rules_hash = @rules.collect do |rule|
      rule.get_rule_hash(@user)
    end
    render :template => 'rules/list_rules'
  end

  # get all the active rules belong to a person
  def get_active_rules_of_person
    @rules = Rule.find_by_id(params[:user_id]).rules
    @active_rules_hash = @rules.find_all{|r| r.active?}.collect do |rule|
      rule.get_rule_hash(@user)
    end
    render :template => 'rules/list_rules'
  end

  # get all the condition_action_sets belong to a rule
  def get_condition_action_sets
    if @rule
      @condition_action_sets = @rule.get_condition_action_sets
    end
  end


end
