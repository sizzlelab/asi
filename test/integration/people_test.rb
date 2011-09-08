require 'test_helper'

class PeopleTest < ActionController::IntegrationTest
  fixtures :people, :clients

  def test_change_details
    new_session do |ossi|
      ossi.logs_in_with({ :username => people(:test).username, :password => "testi",
                          :app_name => clients(:one).name, :app_password => "testi"})
      ossi.gets_person_details({ :id => people(:test).guid })

      ossi.updates_person_details_with({ :id => people(:test).guid,
                                         :person => { :name =>
                                           { :given_name => "Pentteri", :family_name => "Pamppunen" },
                                         :status_message => "Testing..." } })

      ossi.updates_person_details_with({ :id => people(:test).guid,
                                         :person => { :email => "j@example.org" }})
      response_json = ossi.gets_person_details({ :id => people(:test).guid })
      ossi.deletes_account({ :id => people(:test).guid })
    end
  end

  def test_change_password_and_use_location
    new_session do |ossi|
      ossi.logs_in_with({ :username => people(:test).username, :password => "testi",
                          :app_name => clients(:one).name, :app_password => "testi"})

      new_password = "myNEWpass42"
      ossi.changes_password_of_person({ :id => people(:test).guid,
                                        :password => new_password })
      ossi.updates_person_details_with({ :id => people(:test).guid,
                                         :person => { :name =>
                                           { :given_name => "Pentteri",
                                             :family_name => "Pamppunen" },
                                           :status_message => "Testing..." } })

      ossi.logs_out
      ossi.logs_in_with({ :username => people(:test).username, :password => new_password,
                          :app_name => clients(:one).name, :app_password => "testi"})

      ossi.gets_location({ :id => people(:test).guid })
      ossi.updates_location_with({ :id => people(:test).guid,
                                   :location => {
                                     :latitude => 23.2340,
                                     :longitude => 21.2309,
                                     :altitude => 992,
                                     :horizontal_accuracy => 1,
                                     :vertical_accuracy => 1}})

      #TODO make the avatar test work in rails 2.2
      # puts "the following test seems to fail in Rails 2.2. Not yet known why:"
      #       ossi.updates_avatar({ :id => people(:test).guid,
      #                             :file =>
      #                             ActionController::TestUploadedFile.new("#{RAILS_ROOT}/test/fixtures/Bison_skull_pile.png", "image/png", true) })

      ossi.logs_out
    end
  end

  def test_register_and_validate_email
    if Asi::Application.config.VALIDATE_EMAILS
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
      me_too = ossi.get "/people/" + people(:test).guid + "/@self"
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

  def test_availability_checks
    new_session do |kassi|
      kassi.logs_in_with({:app_name => clients(:one).name, :app_password => "testi"})
      
      # unavailable email
      resp = kassi.checks_availability_for(:email => people(:valid_person).email)
      assert resp["email"] == "unavailable", "Taken email falsely reported to be free."
      
      # available email
      resp = kassi.checks_availability_for(:email => "email.not_really@use.by.any.one")
      assert resp["email"] == "available", "Available email falsely reported to be taken."
      
      # unavailable username
      resp = kassi.checks_availability_for(:username => people(:valid_person).username)
      assert resp["username"] == "unavailable", "Taken username falsely reported to be free."
      
      # available username
      resp = kassi.checks_availability_for(:username => "suchastrange_username_that_it_is_not_used")
      assert resp["username"] == "available", "Available username falsely reported to be taken."
      
      # Other one available
      resp = kassi.checks_availability_for(:email => people(:valid_person).email, 
        :username => "suchastrange_username_that_it_is_not_used")
      assert resp["username"] == "available", "Available username falsely reported to be taken."
      assert resp["email"] == "unavailable", "Taken email falsely reported to be free."
      
      # both unavailable
      resp = kassi.checks_availability_for(:email => people(:valid_person).email, 
        :username => people(:valid_person).username)
      assert resp["username"] == "unavailable", "Taken username falsely reported to be free."
      assert resp["email"] == "unavailable", "Taken email falsely reported to be free."
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
