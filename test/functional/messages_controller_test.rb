require 'test_helper'
require 'json'

class MessagesControllerTest < ActionController::TestCase

  def test_list_messages
    get :index, {:format => "json", :channel_id => channels(:julkikanava).guid }, {:cos_session_id => sessions(:session1).id}
    assert_response :ok, @response.body
    json = JSON.parse(@response.body)
    assert_equal 3, json["entry"].length
    
    get :index, {:format => "json", :channel_id => channels(:julkikanava).guid, :page => 1, :per_page => 1 }, {:cos_session_id => sessions(:session1).id}
    assert_response :ok, @response.body
    json = JSON.parse(@response.body)
    assert_equal 1, json["entry"].length    
    
    get :index, {:format => "json", :channel_id => channels(:ryhmakanava).guid }, {:cos_session_id => sessions(:session5).id}
    assert_response :forbidden , @response.body
  end

  def test_create_message
    3.times do |num|
      assert_difference 'Message.find_all_by_channel_id( channels(:julkikanava).id ).length' do
        timestamp = Time.now + (num*2).second
        post :create, {:format => "json", :channel_id => channels(:julkikanava).guid, :message => {:title => "Viesti #{num}.1", :body => "viestikenttä #{num}.1", :updated_at => timestamp, :created_at => timestamp }}, {:cos_session_id => sessions(:session1).id}
        assert_response :created, @response.body
        json = JSON.parse(@response.body)    
        assert_equal "Viesti #{num}.1", json["entry"]["title"]
        assert_equal "viestikenttä #{num}.1", json["entry"]["body"]
        assert_equal sessions(:session1).person.id, json["entry"]["poster_id"]
      end
      assert_difference 'Message.find_all_by_channel_id( channels(:julkikanava).id ).length' do
        timestamp = Time.now + (num*2 + 1).second
        post :create, {:format => "json", :channel_id => channels(:julkikanava).guid, :message => {:title => "Viesti #{num}.2", :body => "viestikenttä #{num}.2", :updated_at => timestamp, :created_at => timestamp }}, {:cos_session_id => sessions(:session10).id}
        assert_response :created, @response.body
        json = JSON.parse(@response.body)    
        assert_equal "Viesti #{num}.2", json["entry"]["title"]
        assert_equal "viestikenttä #{num}.2", json["entry"]["body"]
        assert_equal sessions(:session10).person.id, json["entry"]["poster_id"]
      end
    end
    get :index, {:format => "json", :channel_id => channels(:julkikanava).guid, :per_page => 8, :page => 1}, {:cos_session_id => sessions(:session1).id}
    assert_response :ok
    json = JSON.parse(@response.body)    
    assert_equal 8, json["entry"].length
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
