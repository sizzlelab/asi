require 'test_helper'

class DocTest < ActionController::IntegrationTest

  def test_presence
    system("script/rapidoc/generate > /dev/null")
    missing = []
    Rails.application.routes.routes.each do |r|
      #path = r.segment_keys.inject("") { |str,s| str << s.to_s }
      path = r.path.gsub(/\(\.:format\)/, '')
      if path.start_with? "/doc" and !path.include? "*"
        get path, :format => :html
        assert_response :success, "If response is 500, check /app/helpers/api_helper.rb for correct http_status definitions."
        if @response.body =~ /Documentation missing/
          missing << path
        end
      end
    end
    assert_equal 0, missing.size, "Documentation missing from #{missing.size} api pages: \n#{missing.collect{ |m| "   #{m}\n" }}"
  end

end
