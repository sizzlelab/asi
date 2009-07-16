require 'test_helper'

class CachedCosEventTest < ActiveSupport::TestCase

  @@OPTIONS = { :return_value=>"nil",
    :parameters =>
    { :format => "json",
      :action => "show",
      :id => "c_hs6WxWOr3RofaaWPEYjL",
      :controller => "collections",
      :app_id => "cWslSQyIyr3yiraaWPEYjL" }.to_json,
    :application_id=>"cWslSQyIyr3yiraaWPEYjL",
    :action=>"CollectionsController#show",
    :cos_session_id=>"63601",
    :user_id=>"biPssKjrCr3PQyaaWPEYjL",
    :ip_address=>"128.214.20.122",
    :headers => {"foo" => "bar"}.to_json }


  test "create" do
    event = CachedCosEvent.new(@@OPTIONS)
    assert event.save
  end

  test "upload" do
    begin
      event = CachedCosEvent.new(@@OPTIONS)
      assert event.save
      assert_difference "CachedCosEvent.count", -1 do
        event.upload
      end
    rescue Errno::ECONNREFUSED => e
      puts "No connection to RESSI at #{RESSI_URL}"
    rescue
      assert false,  "Ressi timed out at #{RESSI_URL}"
    end
  end

end