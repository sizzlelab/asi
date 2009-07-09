require 'test_helper'
require 'json'

class LocationsControllerTest < ActionController::TestCase
  fixtures :sessions, :people
  
  def setup
     @controller = LocationsController.new
     @request = ActionController::TestRequest.new
     @response = ActionController::TestResponse.new
   end
  
  def test_get
    get :get, {:user_id => people(:valid_person).id,
                  :format => "json" },
                  { :cos_session_id => sessions(:client_only_session).id }
    assert_response :success
    assert_not_nil assigns["location"]
    json = JSON.parse(@response.body)
    assert_equal locations(:full).longitude, BigDecimal.new(json["longitude"].to_s)
    assert_equal locations(:full).label, json["label"]
    
    assert_nil json["person_id"]
    assert_not_nil(json["updated_at"])
    
    #get location of person without a set location
    get :get, {:user_id => people(:test).id,
                  :format => "json" },
                  { :cos_session_id => sessions(:client_only_session).id }
    assert_response :success
    json = JSON.parse(@response.body)
    assert_nil(assigns["label"])
    assert_nil(assigns["latitude"])
    assert_nil(assigns["updated_at"])
    
  end
  
  def test_update_unauthorized_location
    put :update, {:user_id => people(:valid_person).id,
                  :latitude => 24.852395, 
                  :longitude => -12.1231, 
                  :accuracy => 12,
                  :label => "Experimental grounds \\o/",
                  :format => "json" },
                  { :cos_session_id => sessions(:session2).id }
    assert_response :forbidden
    json = JSON.parse(@response.body)
    
  end
  
  def test_update_full_location
    test_latitude = -24.804007068817
    test_label = "Experimental grounds \\o/"
    put :update, {:user_id => people(:valid_person).id,
                  :latitude => test_latitude, 
                  :longitude => -12.1231, 
                  :accuracy => 12,
                  :label => test_label,
                  :format => "json" },
                  { :cos_session_id => sessions(:session1).id }
    assert_response :success
    json = JSON.parse(@response.body)
    
    #check that fields updated correctly
    assert_equal BigDecimal.new(test_latitude.to_s), Person.find_by_id( people(:valid_person).id).location.latitude
    assert_equal test_label, Person.find_by_id( people(:valid_person).id).location.label
  end
  
  def test_update_with_security_token
      
    get :fetch_location_security_token, { :user_id => people(:valid_person).id, :format => "json"},
                                        { :cos_session_id => sessions(:session1).id }
    
    assert_response :ok
    json = JSON.parse(@response.body)
    security_token = json["location_security_token"]
    
    put :update, {:latitude => -24.804007068817, 
                  :longitude => -12.804007068817, 
                  :accuracy => 12,
                  :label => "Testing",
                  :format => "json" ,
                  :location_security_token => security_token},
                 {:cos_session_id => sessions(:session1).id}
    
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
       
  end
  
  def test_update_with_invalid_security_token
    put :update, {:latitude => -24.804007068817, 
                  :longitude => -12.804007068817, 
                  :accuracy => 12,
                  :label => "Testing",
                  :format => "json" ,
                  :location_security_token => "security_token"},
                 {:cos_session_id => sessions(:session1).id}
    
    assert_response :forbidden, @response.body
    json = JSON.parse(@response.body)
  end
  
  def test_update_with_username_and_password
    test_latitude =  -24.804007068817
    test_longitude = -12.804007068817
     put :update, {:latitude => test_latitude, 
                   :longitude => test_longitude, 
                   :accuracy => 12,
                   :label => "Testing",
                   :format => "json" ,
                   :username => "kusti",
                   :password => "testi"},
                  {:cos_session_id => sessions(:session1).id}
    
    assert_response :success, @response.body
    json = JSON.parse(@response.body)
    
    assert_equal BigDecimal.new(test_latitude.to_s), Person.find_by_id( people(:valid_person).id).location.latitude
    assert_equal BigDecimal.new(test_longitude.to_s), Person.find_by_id( people(:valid_person).id).location.longitude
  end
  
  # Partial location update no longer possible as of version 2009-02-26:
  
  #def test_update_partial_location
  #  original_label = Person.find_by_id( people(:valid_person).id).location.label
  #  original_longitude = Person.find_by_id( people(:valid_person).id).location.longitude
  #  test_label =  "New exciting location"
  #  put :update, {:user_id => people(:valid_person).id,
  #                :label => test_label,
  #                :format => "json" },
  #                { :cos_session_id => sessions(:session1).id }
  #  assert_response :success
  #  json = JSON.parse(@response.body)
  #  
  #  #check that fields upadated correctly
  #  assert_equal test_label, Person.find_by_id( people(:valid_person).id).location.label
  #  
  #  #check that other fields not touched
  #  assert_equal(original_longitude, Person.find_by_id( people(:valid_person).id).location.longitude)
  #end
  
  def test_time_stamp_update
     timestamp = Person.find_by_id( people(:valid_person).id).location.updated_at
     put :update, {:user_id => people(:valid_person).id,
                   :label => "New exciting location",
                   :format => "json" },
                   { :cos_session_id => sessions(:session1).id }
     assert_response :success
     json = JSON.parse(@response.body)
      
     assert_not_equal(timestamp, Person.find_by_id( people(:valid_person).id).location.updated_at)
  end
end
