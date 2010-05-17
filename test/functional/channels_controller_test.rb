# -*- coding: utf-8 -*-
require 'test_helper'
require 'json'

class ChannelsControllerTest < ActionController::TestCase

  def test_index_channels
    get :index, {:format => "json"}, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_not_equal 0, json['entry'].length

    get :index, { :person_id => people(:valid_person).id, :format => "json" }, { :cos_session_id => sessions(:session1).id}
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_not_equal 0, json['entry'].length

    get :index, { :group_id => groups(:open).id, :format => "json" }, { :cos_session_id => sessions(:session1).id}
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_not_equal 0, json['entry'].length

    get :index, { :search => "testaa", :format => "json"}, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_not_equal 0, json['entry'].length
    
    get :index, { :format => "json", :page => 2, :per_page => 3 }, {:cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_equal 3, json['entry'].length

    get :index, { :person_id => people(:valid_person).id, :format => "json" }, { :cos_session_id => sessions(:session1).id}
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    json['entry'].each do |channel|
      assert_not_equal 'private', channel['channel_type']
    end

    get :index, { :include_private => "true", :person_id => people(:valid_person).id, :format => "json" }, { :cos_session_id => sessions(:session1).id}
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    one_matches = false
    json['entry'].each do |channel|
      if channel['channel_type'] == "private"
        one_matches = true
      end
    end
    assert one_matches

    get :index, { :type_filter => "private", :person_id => people(:valid_person).id, :format => "json" }, { :cos_session_id => sessions(:session1).id}
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    json['entry'].each do |channel|
      assert_equal 'private', channel['channel_type']
    end

    get :index, { :type_filter => "!public", :person_id => people(:valid_person).id, :format => "json" }, { :cos_session_id => sessions(:session1).id}
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_not_equal 0, json['entry'].length
    json['entry'].each do |channel|
      assert_not_equal 'public', channel['channel_type']
    end

    # test hidden flag
    get :index, { :search => "channel", :format => "json"}, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_not_equal 0, json['entry'].length
    json['entry'].each do |channel|
      assert_equal false, channel['hidden']
    end

    get :index, { :format => "json" }, { :cos_session_id => sessions(:session1).id}
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_not_equal 0, json['entry'].length
    json['entry'].each do |channel|
      assert_equal false, channel['hidden']
    end

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

    post :create, {:format => "json", :channel => {:name => "testiprivate", :description => "test private create", :channel_type => "private"} }, { :cos_session_id => sessions(:session1).id }
    assert_response :created, @response.body
    json = JSON.parse(@response.body)
    assert_equal json["entry"]["name"], "testiprivate"

    post :create, {:format => "json", :channel => {:channel_type => "group", :description => "", :name => "1"}}, { :cos_session_id => sessions(:session1).id }
    assert_response :bad_request, @response.body

    post :create, {:format => "json", :channel => {:channel_type => "group", :description => "gsdgsGD", :name => "testiryhmä", :group_id => groups(:open)}}, { :cos_session_id => sessions(:session1).id }
    assert_response :created, @response.body
    assert_equal 1, assigns["channel"].group_subscribers.size

    # test create hidden (public) channel
    post :create, {:format => "json", :channel => {:name => "anotherhiddenchannel", :description => "Another hidden (public) channel", :channel_type => "public", :hidden => true} }, { :cos_session_id => sessions(:session1).id }
    assert_response :created, @response.body
    json = JSON.parse(@response.body)
    assert_equal "anotherhiddenchannel", json["entry"]["name"]
    assert_equal true, json["entry"]["hidden"]

    # test fail person_id with create non-private channel
    post :create, {:format => "json", :channel => {:channel_type => "public", :description => "", :name => "footestcreate", :person_id => people(:joe_public).id}}, { :cos_session_id => sessions(:session1).id }
    assert_response :bad_request, @response.body

    # test fail invalid person_id with with create private channel
    post :create, {:format => "json", :channel => {:name => "testiprivate", :description => "test private create with invalid person", :channel_type => "private", :person_id => 9999999} }, { :cos_session_id => sessions(:session1).id }
    assert_response :bad_request, @response.body

    # test person_id with with create private channel
    post :create, {:format => "json", :channel => {:name => "testiprivate", :description => "test private create with person", :channel_type => "private", :person_id => people(:joe_public).guid} }, { :cos_session_id => sessions(:session1).id }
    assert_response :created, @response.body
    json = JSON.parse(@response.body)
    assert_equal 2, assigns["channel"].user_subscribers.length
    assert assigns["channel"].user_subscribers.include?(people(:valid_person))
    assert assigns["channel"].user_subscribers.include?(people(:joe_public))
  end

  def test_delete_channel
    login_as channels(:julkikanava).owner, clients(:one)
    delete :delete, {:format => "json", :channel_id => channels(:julkikanava).guid}
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

    get :show, {:format => "json", :channel_id => channels(:hiddenchannel).guid }, { :cos_session_id => sessions(:session1).id }
    assert_response :ok, @response.body
    json = JSON.parse(@response.body)
    assert_equal channels(:hiddenchannel).name, json["entry"]["name"]
  end

  def test_edit_channel
    put :edit, {:format => "json", :channel_id => channels(:julkikanava).guid, :channel => {:name => "Muutettu", :description => "Muutettu description", :owner_id => people(:test).id }}, { :cos_session_id => sessions(:session1).id }
    assert_response :ok, @response.body
    assert_equal "Muutettu", assigns["channel"]["name"]
    assert_equal "Muutettu description", assigns["channel"]["description"]
    assert assigns["channel"].user_subscribers.include?(people(:test))
  end

  def test_subscribe
    post :subscribe, {:format => "json", :channel_id => channels(:testikanava).guid, :group_id => groups(:hidden).id }, { :cos_session_id => sessions(:session1).id }
    assert_response :created, @response.body
    assert_equal 1, assigns["channel"].group_subscribers.length

    post :subscribe, {:format => "json", :channel_id => channels(:julkikanava).guid, :group_id => groups(:open).id }, { :cos_session_id => sessions(:session5).id }
    assert_response :bad_request, @response.body
    assert_equal 0, assigns["channel"].group_subscribers.length

    post :subscribe, {:format => "json", :channel_id => channels(:julkikanava).guid, :group_id => "agaskdjghasdlgha" }, { :cos_session_id => sessions(:session1).id }
    assert_response :bad_request, @response.body
    assert_equal 0, assigns["channel"].group_subscribers.length

    login_as people(:valid_person).contacts[0]
    post :subscribe, {:format => "json", :channel_id => channels(:kaverikanava).guid, :group_id => nil }
    assert_response :created, @response.body
    assert_equal 2, assigns["channel"].user_subscribers.length

    post :subscribe, {:format => "json", :channel_id => channels(:kaverikanava).guid }, { :cos_session_id => sessions(:session5).id }
    assert_response :forbidden, @response.body
    assert_equal 2, assigns["channel"].user_subscribers.length

    # test fail subscribe to private channel without person_id
    post :subscribe, {:format => "json", :channel_id => channels(:privatechannel).guid }, { :cos_session_id => sessions(:session2).id }
    assert_response :bad_request, @response.body
    assert_equal 1, assigns["channel"].user_subscribers.length

    # test fail subscribe person_id to public channel
    post :subscribe, {:format => "json", :channel_id => channels(:julkikanava).guid, :person_id => people(:test).id }, { :cos_session_id => sessions(:session1).id }
    assert_response :bad_request, @response.body
    assert_equal 2, assigns["channel"].user_subscribers.length

    # test subscribe person_id to private channel if owner
    post :subscribe, {:format => "json", :channel_id => channels(:privatechannel).guid, :person_id => people(:test).id }, { :cos_session_id => sessions(:session1).id }
    assert_response :created, @response.body
    assert_equal 2, assigns["channel"].user_subscribers.length

    # test subscribe person_id to private channel if subscriber
    login_as people(:test)
    post :subscribe, {:format => "json", :channel_id => channels(:privatechannel).guid, :person_id => people(:joe_public).id }
    assert_response :created, @response.body
    assert_equal 3, assigns["channel"].user_subscribers.length

    # test not subscribe person_id to private channel if not owner/subscriber
    login_as people(:random_stranger)
    post :subscribe, {:format => "json", :channel_id => channels(:privatechannel).guid, :person_id => people(:friend).id }, { :cos_session_id => sessions(:session12).id }
    assert_response :forbidden, @response.body
    assert_equal 3, assigns["channel"].user_subscribers.length
  end

  def test_unsubscribe
    login_as channels(:julkikanava).owner
    assert_equal 2, channels(:julkikanava).user_subscribers.length

    delete :unsubscribe, {:format => "json", :channel_id => channels(:julkikanava).guid, :person_id => people(:contact).guid }
    assert_response :ok, @response.body
    assert_equal 1, assigns["channel"].user_subscribers.length

    delete :unsubscribe, {:format => "json", :channel_id => channels(:julkikanava).guid, :person_id => nil }, { :cos_session_id => sessions(:session1).id }
    assert_response :ok, @response.body
    assert_equal 0, assigns["channel"].user_subscribers.length

    delete :unsubscribe, {:format => "json", :channel_id => channels(:ryhmakanava).guid, :group_id => groups(:open).id }, { :cos_session_id => sessions(:session1).id }
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
