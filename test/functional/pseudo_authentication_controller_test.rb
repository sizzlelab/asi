require 'test_helper'

class PseudoAuthenticationControllerTest < ActionController::TestCase

  def test_login
    post :login, { :user_id => people(:valid_person).id, :client_id => clients(:one).id, :format => "json" }
    assert_response :success
    assert_equal people(:valid_person).id.to_s, session["user"]
    assert_equal clients(:one).id.to_s, session["client"]
  end

  def test_logout
    test_login
    delete :login, { :format => "json" }
    assert_response :success
    assert_nil session["user"]
    assert_nil session["client"]
  end

end
