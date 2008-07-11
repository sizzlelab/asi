require 'test_helper'

class SessionTest < ActiveSupport::TestCase
  
  def setup 
    @error_messages = ActiveRecord::Errors.default_error_messages
  end
  
  def test_session_validity
    assert sessions(:session1).valid?    
  end

  # Check uniqueness session id.
  def test_uniqueness_of_session_id
    session_repeat = Session.new(:id => sessions(:session1).id)
    assert ! session_repeat.valid?
  end
end
