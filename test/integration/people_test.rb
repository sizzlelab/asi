require 'test_helper'

class PeopleTest < ActionController::IntegrationTest
  fixtures :people, :clients

  def test_change_details
    new_session do |ossi|
      ossi.logs_in_with({ :username => people(:test).username, :password => "testi", 
                          :app_name => clients(:one).name, :app_password => "testi"})
      ossi.gets_person_details({ :id => people(:test).id })
      
      ossi.updates_person_details_with({ :id => people(:test).id, 
                                         :person => { :name => 
                                           { :given_name => "Pentteri", :family_name => "Pamppunen" },
                                         :status_message => "Testing..." } })

      ossi.updates_person_details_with({ :id => people(:test).id, 
                                         :person => { :email => "j@example.org" }})
      response_json = ossi.gets_person_details({ :id => people(:test).id })  
      ossi.deletes_account({ :id => people(:test).id })
    end
  end

  def test_change_password_and_use_location
    new_session do |ossi|
      ossi.logs_in_with({ :username => people(:test).username, :password => "testi", 
                          :app_name => clients(:one).name, :app_password => "testi"})

      new_password = "myNEWpass42"
      ossi.changes_password_of_person({ :id => people(:test).id, 
                                        :password => new_password })
      ossi.updates_person_details_with({ :id => people(:test).id, 
                                         :person => { :name => 
                                           { :given_name => "Pentteri", 
                                             :family_name => "Pamppunen" },
                                           :status_message => "Testing..." } })

      ossi.logs_out
      ossi.logs_in_with({ :username => people(:test).username, :password => new_password, 
                          :app_name => clients(:one).name, :app_password => "testi"})

      ossi.gets_location({ :id => people(:test).id })
      ossi.updates_location_with({ :id => people(:test).id,
                                   :location => {
                                     :latitude => 23.2340,
                                     :longitude => 21.2309,
                                     :altitude => 992,
                                     :horizontal_accuracy => 1,
                                     :vertical_accuracy => 1}})
                                     
      #TODO make the avatar test work in rails 2.2
      # puts "the following test seems to fail in Rails 2.2. Not yet known why:"
      #       ossi.updates_avatar({ :id => people(:test).id, 
      #                             :file => 
      #                             ActionController::TestUploadedFile.new("#{RAILS_ROOT}/test/fixtures/Bison_skull_pile.png", "image/png", true) })
      
      ossi.logs_out
    end
  end

  def test_register_and_validate_email
    if VALIDATE_EMAILS
      new_session do |kassi|
        kassi.logs_in_with({:app_name => clients(:one).name, :app_password => "testi"})
        kassi.creates_user_with({:username => "Testimies69", :password => "testi", 
                                 :email => "testimies69@example.com" })
        
        kassi.logs_out
        # "receive email"
        confirmation_key = Person.find_by_username("Testimies69").pending_validation.key
      
        #first: Login is not possible, because email is not validated
        kassi.logs_in_with({:app_name => clients(:one).name, :app_password => "testi",
                            :username => "Testimies69", :password => "testi", 
                            :expected_response => :forbidden})
    
        #Confirm email
        kassi.confirms_email_with(:key => confirmation_key)  
    
        #Login should work now
        kassi.logs_in_with({:app_name => clients(:one).name, :app_password => "testi",
                            :username => "Testimies69", :password => "testi", 
                            :expected_response => :created})
      end 
    end
  end

  def test_me_syntax 
    new_session do |ossi|
      ossi.logs_in_with({ :username => people(:test).username, :password => "testi", 
                          :app_name => clients(:one).name, :app_password => "testi"})
      me_too = ossi.get "/people/" + people(:test).id + "/@self"
      ossi.assert_response :success
      me = ossi.get '/people/@me/@self'
      ossi.assert_response :success
      assert_same(me, me_too)
      ossi.logs_out
      
      ossi.logs_in_with({:app_name => clients(:one).name, :app_password => "testi"})
      ossi.get '/people/@me/@self'
      ossi.assert_response :unauthorized
      
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
