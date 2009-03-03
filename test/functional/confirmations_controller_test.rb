require 'test_helper'

class ConfirmationsControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  def test_confirmation_works_correctly
    validation = PendingValidation.find_by_key("testkey12")
    assert_not_nil(validation)
    get :confirm_email, {:key => "testkey12"}
    assert_response :success, @response.body
    assert_template "confirmations/confirm_email"
    validation = PendingValidation.find_by_key("testkey12")
    assert_nil(validation)
    get :confirm_email, {:key => "testkey12"}
    assert_response :success, @response.body
    assert_template "confirmations/not_found"
  end
end
