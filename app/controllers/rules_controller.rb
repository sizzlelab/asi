class RulesController < ApplicationController
  layout "rules"
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
  def show
    @rule = Rule.find_by_id(params['rule_id'])
    if ! @rule
      render :status => :not_found and return
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



  def destroy
    @rule = Rule.find_by_id(params['id'])
    @rule.destroy
    if ! @rule
      render :status => :not_found and return
    end
    redirect_to rules_path
  end

  def enable
    @rule = Rule.find_by_id(params['rule_id'])
    if @rule.update_attribute(:state, 'active')
        flash[:notice] = 'Rule was successfully updated.'
        redirect_to rules_path and return
    else
        flash[:notice] = 'Error.'
    end
  end
#
    def disable
    flash[:notice] = 'disabled method.'
    @rule = Rule.find_by_id(params['rule_id'])
    if @rule.update_attribute(:state, 'inactive')
        flash[:notice] = 'Rule was successfully updated.'
        redirect_to rules_path and return
    else
        flash[:notice] = 'Error.'
    end
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
