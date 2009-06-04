require 'test_helper'

class DocTest < ActionController::IntegrationTest

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
