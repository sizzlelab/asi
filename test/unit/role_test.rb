require 'test_helper'

class RoleTest < ActiveSupport::TestCase

  # Tests all three role types with valid examples
  def test_should_be_valid_roles
    assert roles(:valid_user).valid?, "User should be a valid role, but isn't."
    assert roles(:valid_moderator).valid?, "Moderator should be a valid role, but isn't."
    assert roles(:valid_administrator).valid?, "Administrator sould be a valid role, but isn't."
  end
  
  # Tests what happens if the role title is invalid
  def test_should_have_invalid_role_title
    assert ! roles(:invalid_title).valid?, "'Hangaround' shouldn't be a valid role title."
  end

  # Tests roles with one of the required fields missing
  def test_should_have_missing_fields
    assert ! roles(:missing_person_id).valid?
    assert ! roles(:missing_client_id).valid?
    assert ! roles(:missing_title).valid?
  end

end
