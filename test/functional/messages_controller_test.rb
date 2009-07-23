require 'test_helper'
require 'json'

class MessagesControllerTest < ActionController::TestCase

  def test_list_messages
    get :list, {:format => "json", :channel_id => channels(:julkikanava).guid }, {:cos_session_id => sessions(:session1).id}
    assert_response :ok, @response.body
    json = JSON.parse(@response.body)
    assert_equal 3, json["entry"].length
    
    get :list, {:format => "json", :channel_id => channels(:julkikanava).guid, :page => 1, :per_page => 1 }, {:cos_session_id => sessions(:session1).id}
    assert_response :ok, @response.body
    json = JSON.parse(@response.body)
    assert_equal 1, json["entry"].length    
    
    get :list, {:format => "json", :channel_id => channels(:ryhmakanava).guid }, {:cos_session_id => sessions(:session5).id}
    assert_response :forbidden , @response.body
  end

  def test_create_message
    post :create, {:format => "json", :channel_id => channels(:julkikanava).guid, :message => {:title => "testiviesti", :body => "viestikenttä" }}, {:cos_session_id => sessions(:session1).id}
    assert_response :created, @response.body
    json = JSON.parse(@response.body)    
    assert_equal "testiviesti", json["entry"]["title"]
  end

  def test_show_message
    get :show, {:format => "json", :channel_id => channels(:julkikanava).guid, :msg_id => messages(:testiviesti1).guid }, {:cos_session_id => sessions(:session1).id}
    assert_response :ok, @response.body
    json = JSON.parse(@response.body)
    assert_equal messages(:testiviesti1).body, json["entry"]["body"]
  end

  def test_delete_message
    delete :delete, {:format => "json", :channel_id => channels(:julkikanava).guid, :msg_id => messages(:testiviesti1).guid }, {:cos_session_id => sessions(:session1).id}
    assert_response :ok, @response.body
    assert !Message.find_by_guid(messages(:testiviesti1).guid)
    
    delete :delete, {:format => "json", :channel_id => channels(:julkikanava).guid, :msg_id => messages(:testiviesti3).guid }, {:cos_session_id => sessions(:session7).id}
    assert_response :ok, @response.body
    assert !Message.find_by_guid(messages(:testiviesti3).guid)
  end

end
