require 'test_helper'

class PeopleTest < ActionController::IntegrationTest
  fixtures :people, :clients
  
  def test_change_details
    new_session do |ossi|
      ossi.logs_in_with({ :username => people(:test).username, :password => "testi", :client_name => clients(:one).name, :client_password => "testi"})
      ossi.gets_person_details({ :id => people(:test).id })
      ossi.updates_person_details_with({ :id => people(:test).id, 
                                         :person => { :name => { :given_name => "Pentteri", :family_name => "Pamppunen" },
                                         :status_message => "Testing..." } })

      ossi.updates_person_details_with({ :id => people(:test).id, 
                                         :person => { :email => "j@example.org" }})
      ossi.deletes_account({ :id => people(:test).id })
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
