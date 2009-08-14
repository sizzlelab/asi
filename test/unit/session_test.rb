# == Schema Information
#
# Table name: sessions
#
#  id         :integer(4)      not null, primary key
#  person_id  :integer(4)
#  ip_address :string(255)
#  path       :string(255)
#  created_at :datetime
#  updated_at :datetime
#  client_id  :string(255)
#

require 'test_helper'

class SessionTest < ActiveSupport::TestCase
    
  def test_session_validity
    assert sessions(:session1).valid?    
  end

  # Check uniqueness session id.
  def test_uniqueness_of_session_id
    session_repeat = Session.new(:id => sessions(:session1).id)
    assert ! session_repeat.valid?
  end
end
