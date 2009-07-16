require 'test_helper'
require 'json'

class ChannelsControllerTest < ActionController::TestCase
  
  def test_list_channels
    get :list, {:format => "json"}, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_not_equal json, []
    
    get :list, { :person_id => people(:valid_person).id, :format => "json" }, { :cos_session_id => sessions(:session1).id}
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_not_equal json, []
    
    get :list, { :group_id => groups(:closed).id, :format => "json" }, { :cos_session_id => sessions(:session1).id}
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_not_equal json, []


# TODO! FIX SEARCHING!    
#    get :list, { :search => "Julki", :format => "json"}, { :cos_session_id => sessions(:session1).id }
#    assert_response :success, @response.body
#    json = JSON.parse(@response.body)
#    assert_not_equal json, []
#    print json.inspect
    
  end
  
  def test_create_channel
    post :create, {:format => "json", :name => "testikanava", :description => "testausta", 
                   :type => "public"}, { :cos_session_id => sessions(:session1).id }
    assert_response :created, @response.body
    print @response.body
    json = JSON.parse(@response.body)
    assert_equal json["channel"]["name"], "testikanava"
    
    post :create, {:format => "json", :id => "gfpasdjga", :name => "toinen testi", :description => nil, :type => nil}, { :cos_session_id => sessions(:session1).id}
    assert_response :created, @response.body
    json = JSON.parse(@response.body)
    assert_equal json["channel"]["channel_type"], "public"
    assert_equal json["channel"]["id"], "gfpasdjga"
    
    post :create, {:format => "json", :id => nil, :type => "group", :name => nil, :group_subscriptions => groups(:closed).id}, { :cos_session_id => sessions(:session1).id }
    assert_response :created, @response.body
    json = JSON.parse(@response.body)
    assert_equal json["channel"]["name"], groups(:closed).title
    assert_equal 1, assigns["channel"].group_subscriptions.length
  end

  def test_delete_channel
    delete :delete, {:format => "json", :channel_id => channels(:julkikanava).guid}, { :cos_session_id => sessions(:session1).id }
    assert_response :ok, @response.body
    assert !Channel.find_by_guid(channels(:julkikanava).guid)
    
    delete :delete, {:format => "json", :channel_id => channels(:ryhmakanava).guid}, { :cos_session_id => sessions(:session1).id }
    assert_response :forbidden, @response.body
    assert Channel.find_by_guid(channels(:ryhmakanava).guid)
  end

  def test_show_channel
    get :show, {:format => "json", :channel_id => channels(:julkikanava).guid }, { :cos_session_id => sessions(:session1).id }
    assert_response :ok, @response.body
    json = JSON.parse(@response.body)
    assert_equal channels(:julkikanava).name, json["channel"]["name"]
    
    get :show, {:format => "json", :channel_id => channels(:ryhmakanava).guid }, { :cos_session_id => sessions(:session5).id }
    assert_response :forbidden, @response.body
  end

  def test_edit_channel
    put :edit, {:format => "json", :channel_id => channels(:julkikanava).guid, :name => "Muutettu", :description => "Muutettu description", :owner => people(:test).id }, { :cos_session_id => sessions(:session1).id }
    assert_response :created, @response.body
    assert_equal "Muutettu", assigns["channel"]["name"]
    assert_equal "Muutettu description", assigns["channel"]["description"]
    assert assigns["channel"].user_subscribers.include?(people(:test))
  end

  def test_subscribe
    post :subscribe, {:format => "json", :channel_id => channels(:julkikanava).guid, :group_subscriptions => groups(:tkk).id }, { :cos_session_id => sessions(:session1).id }
    assert_response :created, @response.body
    assert_equal 2, assigns["channel"].group_subscribers.length

    post :subscribe, {:format => "json", :channel_id => channels(:julkikanava).guid, :group_subscriptions => groups(:open).id }, { :cos_session_id => sessions(:session5).id }
    assert_response :forbidden, @response.body
    assert_equal 2, assigns["channel"].group_subscribers.length

    post :subscribe, {:format => "json", :channel_id => channels(:julkikanava).guid, :group_subscriptions => "agaskdjghasdlgha" }, { :cos_session_id => sessions(:session1).id }
    assert_response :not_found, @response.body
    assert_equal 2, assigns["channel"].group_subscribers.length

    post :subscribe, {:format => "json", :channel_id => channels(:ryhmakanava).guid, :group_subscriptions => [groups(:tkk).id, groups(:open).id] }, { :cos_session_id => sessions(:session5).id }
    assert_response :created, @response.body
    assert_equal 3, assigns["channel"].group_subscribers.length

    
    post :subscribe, {:format => "json", :channel_id => channels(:julkikanava).guid, :user_subscriptions => people(:test).id, :group_subscriptions => nil }, { :cos_session_id => sessions(:session1).id }
    assert_response :created, @response.body
    assert_equal 3, assigns["channel"].user_subscribers.length
    
    post :subscribe, {:format => "json", :channel_id => channels(:julkikanava).guid, :user_subscriptions => [people(:contact).id, people(:person1).id] }, { :cos_session_id => sessions(:session1).id }
    assert_response :created, @response.body
    assert_equal 5, assigns["channel"].user_subscribers.length
    
    post :subscribe, {:format => "json", :channel_id => channels(:kaverikanava).guid, :group_subscriptions => nil, :user_subscriptions => nil }, { :cos_session_id => sessions(:session10).id }
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
    assert json["group_subscriptions"].include?(groups(:closed).id)
    assert json["user_subscriptions"].include?(people(:valid_person).id)
    assert json["user_subscriptions"].include?(people(:contact).id)
  end

end
