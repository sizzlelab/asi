require 'test_helper'

class ConnectionTest < ActiveSupport::TestCase

  def setup
    @person = people(:valid_person)
    @contact = people(:contact)
  end

  def test_request
    Connection.request(@person, @contact)
    assert Connection.exists?(@person, @contact)
    assert_status @person, @contact, 'pending'
    assert_status @contact, @person, 'requested'
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

  private

  # Verify the existence of a connection with the given status.
  def assert_status(person, contact, status)
    connection = Connection.find_by_person_id_and_contact_id(person, contact)
    assert_equal status, connection.status
  end

end
