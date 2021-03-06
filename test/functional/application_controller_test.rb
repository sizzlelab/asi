require 'test_helper'
require 'json'

class ApplicationControllerTest < ActionController::TestCase

  def setup
    @controller = ApplicationController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end

  if  APP_CONFIG.log_to_ressi
    def test_logging
      assert_difference "CachedCosEvent.count", 1 do
        get :test, { :app_id => clients(:one).id, :event_id => "index_test" }, { :cos_session_id => sessions(:session1).id }
        assert_response :success
      end
      event = CachedCosEvent.find(:first, :order => 'created_at DESC')
      event.attributes.each do |attribute|
        assert_not_nil event.send(attribute[0]), attribute[0]
        assert_not_equal event.send(attribute[0]).to_s.size, 0
      end
      assert_nothing_raised do
        begin
          event.upload
        rescue Errno::ECONNREFUSED => e
          puts "No connection to RESSI at #{APP_CONFIG.ressi_url}"
        end
      end
    end
  end

end
