require 'test_helper'
require 'json'

class RulesControllerTest < ActionController::TestCase

  fixtures :actions
  fixtures :conditions
  fixtures :condition_action_sets
  fixtures :rules
  fixtures :people
  fixtures :sessions

  def test_create
    
      
  end

  # put this method in controller for testing purpose, should be moved to model
  # later
  def test_create_default_profile_rule
      post :create_default_profile_rule, {:person_id => sessions(:session1).person.id,
      :rule_name => "profile rule",
      :state => "active",
      :logic => "and",
      :format => 'json'}, { :cos_session_id => sessions(:session1).id }
      assert_response :created, @response.body
      json = JSON.parse(@response.body)
      #puts json.inspect
      assert id = json["rule"]["id"]
      rule = Rule.find(id)
      assert(rule, "Created rule not found.")
      assert_equal(sessions(:session1).person.id, rule.person_id)
      # assert associated condition_action_sets are inserted
      
  end


  def test_index
    
  end


  def test_show

  end


  def test_get_condition_action_sets
    
  end


  def test_update

  end


  def test_destroy

  end


  def test_enable

  end


  def test_disable
    
  end
end
