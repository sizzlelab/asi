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
      
      ossi.updates_avatar({ :id => people(:test).id, 
                            :file => 
                            ActionController::TestUploadedFile.new("#{RAILS_ROOT}/test/fixtures/Bison_skull_pile.png", "image/png", true), :full_image_size => '"240x300"', :thumbnail_size => '"50x64"' })

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
