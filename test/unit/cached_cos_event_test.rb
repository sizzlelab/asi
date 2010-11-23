# == Schema Information
#
# Table name: cached_cos_events
#
#  id                :integer(4)      not null, primary key
#  user_id           :string(255)
#  application_id    :string(255)
#  cos_session_id    :string(255)
#  ip_address        :string(255)
#  action            :string(255)
#  parameters        :string(255)
#  return_value      :string(255)
#  headers           :text
#  created_at        :datetime
#  updated_at        :datetime
#  semantic_event_id :string(255)
#

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
    :semantic_event_id => "hololooo",
    :headers => {"foo" => "bar"}.to_json }


  test "create" do
    event = CachedCosEvent.new(@@OPTIONS)
    assert event.save
  end

  if APP_CONFIG.log_to_ressi
    test "upload" do
      begin
        event = CachedCosEvent.new(@@OPTIONS)
        assert event.save
        assert_difference "CachedCosEvent.count", -1 do
          event.upload
        end
      rescue Errno::ECONNREFUSED => e
        puts "No connection to RESSI at #{APP_CONFIG.ressi_url}"
      rescue Exception => e
        assert false,  "Ressi timed out at #{APP_CONFIG.ressi_url}"
      end
    end
  end

end
