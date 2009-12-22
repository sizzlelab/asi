require 'test_helper'

class Coreui::ProfileControllerTest < ActionController::TestCase

  test "update" do
    person = people(:valid_person)
    login_as person
    put :update, { :id => person.id, :person => { :status_message => "Testing", :name_attributes => { :given_name => "Jaakko" }}}

    person.reload
    
    assert_equal "Testing", person.status_message
    assert_equal "Jaakko", person.name.given_name
  end
  
end
