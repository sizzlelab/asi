require 'test_helper'
require 'json'

class ChannelsControllerTest < ActionController::TestCase

  def test_index_channels
    get :index, {:format => "json"}, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_not_equal json['entry'], []

    get :index, { :person_id => people(:valid_person).id, :format => "json" }, { :cos_session_id => sessions(:session1).id}
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_not_equal json['entry'], []

    get :index, { :group_id => groups(:closed).id, :format => "json" }, { :cos_session_id => sessions(:session1).id}
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_not_equal json['entry'], []

    get :index, { :search => "testaa", :format => "json"}, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_not_equal json['entry'], []    
  end

  def test_create_channel
    post :create, {:format => "json", :channel => {:name => "testikanava", :description => "testausta", :channel_type => "public"} }, { :cos_session_id => sessions(:session1).id }
    assert_response :created, @response.body
    json = JSON.parse(@response.body)
    assert_equal json["entry"]["name"], "testikanava"

    post :create, {:format => "json", :channel => {:name => "toinen testi", :description => nil, :channel_type => nil}}, { :cos_session_id => sessions(:session1).id}
    assert_response :created, @response.body
    json = JSON.parse(@response.body)
    assert_equal json["entry"]["channel_type"], "public"

    post :create, {:format => "json", :channel => {:channel_type => "group", :description => "", :name => "1"}}, { :cos_session_id => sessions(:session1).id }
    assert_response :bad_request, @response.body
    
  end

  def test_delete_channel
    delete :delete, {:format => "json", :channel_id => channels(:julkikanava).guid}, { :cos_session_id => sessions(:session1).id }
    assert_response :ok, @response.body
    assert !Channel.find_by_guid(channels(:julkikanava).guid)

    delete :delete, {:format => "json", :channel_id => channels(:ryhmakanava).guid}, { :cos_session_id => sessions(:session6).id }
    assert_response :forbidden, @response.body
    assert Channel.find_by_guid(channels(:ryhmakanava).guid)
  end

  def test_show_channel
    get :show, {:format => "json", :channel_id => channels(:julkikanava).guid }, { :cos_session_id => sessions(:session1).id }
    assert_response :ok, @response.body
    json = JSON.parse(@response.body)
    assert_equal channels(:julkikanava).name, json["entry"]["name"]

    get :show, {:format => "json", :channel_id => channels(:ryhmakanava).guid }, { :cos_session_id => sessions(:session5).id }
    assert_response :forbidden, @response.body
  end

  def test_edit_channel
    put :edit, {:format => "json", :channel_id => channels(:julkikanava).guid, :channel => {:name => "Muutettu", :description => "Muutettu description", :owner_id => people(:test).id }}, { :cos_session_id => sessions(:session1).id }
    assert_response :ok, @response.body
    assert_equal "Muutettu", assigns["channel"]["name"]
    assert_equal "Muutettu description", assigns["channel"]["description"]
    assert assigns["channel"].user_subscribers.include?(people(:test))
  end

  def test_subscribe
    post :subscribe, {:format => "json", :channel_id => channels(:testikanava).guid, :subscription => groups(:hidden).id }, { :cos_session_id => sessions(:session1).id }
    assert_response :created, @response.body
    assert_equal 1, assigns["channel"].group_subscribers.length

    post :subscribe, {:format => "json", :channel_id => channels(:julkikanava).guid, :subscription => groups(:open).id }, { :cos_session_id => sessions(:session5).id }
    assert_response :bad_request, @response.body
    assert_equal 1, assigns["channel"].group_subscribers.length

    post :subscribe, {:format => "json", :channel_id => channels(:julkikanava).guid, :subscription => "agaskdjghasdlgha" }, { :cos_session_id => sessions(:session1).id }
    assert_response :bad_request, @response.body
    assert_equal 1, assigns["channel"].group_subscribers.length
    

    post :subscribe, {:format => "json", :channel_id => channels(:kaverikanava).guid, :subscription => nil }, { :cos_session_id => sessions(:session10).id }
    assert_response :created, @response.body
    assert_equal 2, assigns["channel"].user_subscribers.length

    post :subscribe, {:format => "json", :channel_id => channels(:kaverikanava).guid }, { :cos_session_id => sessions(:session5).id }
    assert_response :forbidden, @response.body
    assert_equal 2, assigns["channel"].user_subscribers.length

  end

  def test_unsubscribe
    delete :unsubscribe, {:format => "json", :channel_id => channels(:julkikanava).guid, :user_subscriptions => people(:contact).id }, { :cos_session_id => sessions(:session1).id }
    assert_response :ok, @response.body
    assert_equal 1, assigns["channel"].user_subscribers.length

    delete :unsubscribe, {:format => "json", :channel_id => channels(:julkikanava).guid, :user_subscriptions => nil }, { :cos_session_id => sessions(:session1).id }
    assert_response :forbidden, @response.body
    assert_equal 1, assigns["channel"].user_subscribers.length

    post :subscribe, {:format => "json", :channel_id => channels(:julkikanava).guid, :user_subscriptions => people(:test).id, :group_subscriptions => nil }, { :cos_session_id => sessions(:session1).id }
    delete :unsubscribe, {:format => "json", :channel_id => channels(:julkikanava).guid, :user_subscriptions => nil }, { :cos_session_id => sessions(:session10).id }
    assert_response :ok, @response.body
    assert_equal 1, assigns["channel"].user_subscribers.length

    delete :unsubscribe, {:format => "json", :channel_id => channels(:julkikanava).guid, :user_subscriptions => nil, :group_subscriptions => groups(:closed).id }, { :cos_session_id => sessions(:session10).id }
    assert_response :forbidden, @response.body
    assert_equal 1, assigns["channel"].group_subscribers.length

    delete :unsubscribe, {:format => "json", :channel_id => channels(:julkikanava).guid, :group_subscriptions => groups(:closed).id }, { :cos_session_id => sessions(:session1).id }
    assert_response :ok, @response.body
    assert assigns["channel"].group_subscribers.empty?

  end

  def test_list_subscriptions
    get :list_subscriptions, {:format => "json", :channel_id => channels(:julkikanava).guid }, { :cos_session_id => sessions(:session1).id }
    assert_response :ok, @response.body
    json = JSON.parse(@response.body)
#    assert json["entry"]["group_subscriptions"].include?(groups(:closed))
#    assert json["entry"]["user_subscriptions"].include?(people(:valid_person))
#    assert json["entry"]["user_subscriptions"].include?(people(:contact))
  end

end
