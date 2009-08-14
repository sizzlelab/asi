# == Schema Information
#
# Table name: connections
#
#  id         :integer(4)      not null, primary key
#  person_id  :integer(4)
#  contact_id :integer(4)
#  status     :string(255)
#  created_at :datetime
#  updated_at :datetime
#

require 'test_helper'

class ConnectionTest < ActiveSupport::TestCase

  def setup
    @person = people(:valid_person)
    @contact = people(:contact)
  end

  def test_request
    Connection.request(@person, @contact)
    assert Connection.exists?(@person, @contact)
    assert_status @person, @contact, 'requested'
    assert_status @contact, @person, 'pending'
  end
  
  def test_accept
    Connection.request(@person, @contact)
    Connection.accept(@person, @contact)
    assert Connection.exists?(@person, @contact)
    assert_status @person, @contact, 'accepted'
    assert_status @contact, @person, 'accepted'  
  end

  def test_breakup
    Connection.request(@person, @contact)
    Connection.breakup(@person, @contact)
    assert !Connection.exists?(@person, @contact)
  end
  
  def test_type
    assert_equal("none", Connection.type(@person, @contact))
    Connection.request(@person, @contact)
    assert_equal("requested", Connection.type(@person, @contact))
    assert_equal("pending", Connection.type(@contact, @person))
    Connection.accept(@person, @contact)
    assert_equal("accepted", Connection.type(@contact, @person))
    assert_equal("accepted", Connection.type(@person, @contact))
    assert_equal("you", Connection.type(@person, @person))
    
  end

  private

  # Verify the existence of a connection with the given status.
  def assert_status(person, contact, status)
    connection = Connection.find_by_person_id_and_contact_id(person, contact)
    assert_equal status, connection.status
  end

end
