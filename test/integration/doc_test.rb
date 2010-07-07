require 'test_helper'

class DocTest < ActionController::IntegrationTest

  def test_presence
    system("script/rapidoc/generate > /dev/null")
    missing = []
    ActionController::Routing::Routes.routes.each do |r|
      path = r.segments.inject("") { |str,s| str << s.to_s }
      if path.start_with? "/doc"
        get path
        assert_response :success, "If response is 500, check /app/helpers/api_helper.rb for correct http_status definitions."
        if @response.body =~ /Documentation missing/
          missing << path
        end
      end
    end
    assert_equal 0, missing.size, "Documentation missing from #{missing.size} api pages: \n#{missing.collect{ |m| "   #{m}\n" }}"
  end

end
