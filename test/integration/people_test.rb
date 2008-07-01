require 'test_helper'

class PeopleTest < ActionController::IntegrationTest
  fixtures :people, :clients
  
  def test_change_details
    new_session do |ossi|
      ossi.logs_in_with({ :session => { :name => people(:test).username, :password => "testi" }, :client_id => clients(:one).id })
      ossi.gets_person_details({ :id => people(:test).id })
      ossi.updates_person_details_with({ :id => people(:test).id, :first_name => "Pentteri" })
      ossi.logs_out
    end
  end

  private

  def new_session
    open_session do |sess|
      sess.extend(COSTestingDSL)
      yield sess if block_given?
    end
  end

end