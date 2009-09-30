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

  test "session_validity" do
    assert sessions(:session1).valid?
  end

  test "uniqueness_of_session_id" do
    session_repeat = Session.new(:id => sessions(:session1).id)
    assert ! session_repeat.valid?
  end

  test "cleanup" do
    Session.cleanup
    s = sessions(:session1)

    class << s
      def record_timestamps
        false
      end
    end

    s.update_attribute "updated_at", 3.weeks.ago
    assert_difference "Session.count", -1 do
      Session.cleanup
    end
  end

end
