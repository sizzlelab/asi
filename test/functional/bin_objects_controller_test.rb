require 'test_helper'

class BinObjectsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index, {:format => "json" }, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    assert_not_nil assigns(:bin_objects)
    json = JSON.parse(@response.body)
    assert_equal 3, json["entry"].length

    get :index, {:format => "json", :page => 2, :per_page => 1 }, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    assert_not_nil assigns(:bin_objects)
    json = JSON.parse(@response.body)
    assert_equal 1, json["entry"].length
    assert_equal "binobj2", json["entry"][0]["name"]
  end

  def test_should_create_and_get_bin_object_from_upload
    post :create, {:binobject => { :data => fixture_file_upload("Australian_painted_lady.jpg","image/jpeg") }}, { :cos_session_id => sessions(:session1).id }

    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_equal "image/jpeg", json["entry"]["content_type"]
    assert_equal "Australian_painted_lady.jpg", json["entry"]["orig_name"]

    upload_guid = json["entry"]["id"]

    # try to show the uploaded bin_object
    get :show_data, { :binobject_id => upload_guid, :format => 'jpg' }, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    assert_not_equal nil, @response.body

    # try to show the uploaded bin_object metadata
    get :show, { :binobject_id => upload_guid }, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_equal "image/jpeg", json["entry"]["content_type"]
    assert_equal "Australian_painted_lady.jpg", json["entry"]["orig_name"]
  end

  def test_should_create_and_get_bin_object_from_regular_post
    post :create, {:binobject => { :data => "testbinobjDATA" }}, { :cos_session_id => sessions(:session1).id }

    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_equal nil, json["entry"]["content_type"]
    assert_equal nil, json["entry"]["orig_name"]

    create_guid = json["entry"]["id"]

    # try to show the created bin_object
    get :show_data, { :binobject_id => create_guid }, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    assert_equal "testbinobjDATA", @response.body

    # try to show the created bin_object metadata
    get :show, { :binobject_id => create_guid }, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_equal nil, json["entry"]["content_type"]
    assert_equal nil, json["entry"]["orig_name"]
  end

  def test_should_create_and_get_bin_object_without_data
    post :create, {:binobject => { :name => "metadataonly" }}, { :cos_session_id => sessions(:session1).id }

    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_equal "metadataonly", json["entry"]["name"]

    mdonly_guid = json["entry"]["id"]

    # try to show the uploaded bin_object
    get :show_data, { :binobject_id => mdonly_guid }, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body

    # try to show the uploaded bin_object metadata
    get :show, { :binobject_id => mdonly_guid }, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_equal "metadataonly", json["entry"]["name"]
  end

  def test_should_show_bin_object_data
    get :show_data, {:binobject_id => bin_objects(:testbinobject1).guid}, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    assert_equal "binobj1data", @response.body
  end

  def test_should_show_bin_object_metadata
    get :show, {:binobject_id => bin_objects(:testbinobject1).guid}, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_equal "binobj1", json["entry"]["name"]
    assert_equal "binobj1guid", json["entry"]["id"]
    assert_nil json["entry"]["data"]
  end

  def test_should_edit
    put :edit, {:binobject_id => bin_objects(:testbinobject1).guid, :binobject => {:name => "binobj1EDITED"}}, { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    assert_equal "binobj1EDITED", json["entry"]["name"]

    # test that cannot edit bin_object that you do not own
    put :edit, {:binobject_id => bin_objects(:testbinobject1).guid, :binobject => {:name => "binobj1EDITED"}}, { :cos_session_id => sessions(:session2).id }
    assert_response :forbidden, @response.body
  end

  def test_should_destroy_bin_object
    assert_difference('BinObject.count', -1) do
      delete :delete, {:binobject_id => bin_objects(:testbinobject1).guid}, { :cos_session_id => sessions(:session1).id }
    end

    assert_difference('BinObject.count', 0) do
      delete :delete, {:binobject_id => bin_objects(:testbinobject1).guid}, { :cos_session_id => sessions(:session2).id }
    end
  end
end
