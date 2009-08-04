class RulesController < ApplicationController

  before_filter :ensure_client_login
  
  # create a new rule
  def create
    parameters_hash = HashWithIndifferentAccess.new(params.clone)
    params = fix_utf8_characters(parameters_hash) #fix nordic letters in person details

    @rule = Rule.create(:person_id => @user.id,
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
    @rule = Rule.find_by_id(params['rule_id'])
    if ! @rule
      render :status => :not_found and return
    end
  end


  # update a rule, and associated conditon_action_sets
  def update
    @rule = Rule.find_by_id(params['rule_id'])
    if @rule.update_attributes(params[:rule])
      ##### update associated condition_action_sets, delete sets first, then add new sets #########
      
      render :status => :ok, :json => @rule.to_json
    else
      render :status => :bad_request, :json => @rule.errors.full_messages.to_json
      @rule = nil
    end
  end

  
  # get all the rules belong to a person
  def get_rules_of_person
    @rules = Rule.find_by_id(params[:user_id]).rules
    @rules_hash = @rules.collect do |rule|
      rule.get_rule_hash(@user)
    end
    render :template => 'rules/list_rules'
  end




end
