# == Schema Information
#
# Table name: roles
#
#  id                      :integer(4)      not null, primary key
#  person_id               :integer(4)
#  client_id               :string(255)
#  title                   :string(255)
#  created_at              :datetime
#  updated_at              :datetime
#  terms_version           :string(255)
#  location_security_token :string(255)
#

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
  
  def test_location_security_token
    role = roles(:valid_user)
    assert role.valid?
    
    security_token = role.location_security_token
    assert security_token
    
    security_token_confirm = role.location_security_token
    
    assert_equal security_token, security_token_confirm
  end

end
