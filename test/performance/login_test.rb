require 'test_helper'
require 'performance_test_help'

class LoginTest < ActionController::PerformanceTest
  # Replace this with your real tests.
  def test_login
    post "/session", :post => {:username => people(:test).username, :password => "testi", :app_name => clients(:one).name, :app_password => "testi"}
  end
end
