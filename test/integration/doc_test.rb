require 'test_helper'

class DocTest < ActionController::IntegrationTest

  def test_presence
    system("script/rapidoc/generate > /dev/null")
    ActionController::Routing::Routes.routes.each do |r|
      path = r.segments.inject("") { |str,s| str << s.to_s }
      if path.start_with? "/api"
        get path
        assert_response :success
        assert ! @response.body =~ /Documentation missing/, "Documentation missing in #{path}"
      end
    end
  end


  def test_doc
    read_page "/"
    read_page "/doc"
    read_page "/doc/"
    read_page "/doc/people"
    read_page "/doc/people/"

    try_to_read_page "/doc/poople"
    try_to_read_page "/foo/bar"
  end

  private
  def read_page(url)
    get url
    assert_response :success
  end

  def try_to_read_page(url)
    get url
    assert_response :not_found
  end

end
