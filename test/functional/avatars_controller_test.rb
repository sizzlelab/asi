require 'test_helper'

class AvatarsControllerTest < ActionController::TestCase

  test "update_and_get_avatar" do
    # try to show the default large thumbnail
    get :show_large_thumbnail, { :user_id => people(:valid_person).guid, :format => 'jpg' }, { :cos_session_id => sessions(:session1).id }
    assert_response :success

    # try to show the default small thumbnail
    get :show_small_thumbnail, { :user_id => people(:valid_person).guid, :format => 'jpg' }, { :cos_session_id => sessions(:session1).id }
    assert_response :success

    # try to upload an avatar
    put :update, { :user_id => people(:valid_person).guid, :file => fixture_file_upload("Australian_painted_lady.jpg","image/jpeg"),
                          :format => 'html' },
                        { :cos_session_id => sessions(:session1).id }
    assert_response :success, @response.body

    # try to show the uploaded avatar
    get :show, { :user_id => people(:valid_person).guid, :format => 'jpg' }, { :cos_session_id => sessions(:session1).id }
    assert_response :success

    # try to show the large thumbnail of the avatar
    get :show_large_thumbnail, { :user_id => people(:valid_person).guid, :format => 'jpg' }, { :cos_session_id => sessions(:session1).id }
    assert_response :success

    # try to show the small thumbnail of the avatar
    get :show_small_thumbnail, { :user_id => people(:valid_person).guid, :format => 'jpg' }, { :cos_session_id => sessions(:session1).id }
    assert_response :success
  end

  test "update_avatar_image_without_suffix" do
    put :update, { :user_id => people(:valid_person).guid, :file => fixture_file_upload("kuva_ilman_paatetta","image/jpeg"),
                          :format => 'html' },
                        { :cos_session_id => sessions(:session1).id }
    assert_response :bad_request
  end

  test "update_avatar_image_with_all_caps" do
    put :update, { :user_id => people(:valid_person).guid, :file => fixture_file_upload("LADY.JPG","image/jpeg"),
                          :format => 'html' },
                        { :cos_session_id => sessions(:session1).id }
    assert_response :success
  end

  test "delete_avatar" do
    login_as people(:valid_association)
    delete :delete, { :user_id => people(:valid_association).guid, :format => 'json' }
    assert_response :success
    json = JSON.parse(@response.body)
  end

end
