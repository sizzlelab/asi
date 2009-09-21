require "test_helper"

class AppDataTest < ActionController::IntegrationTest
  fixtures :people, :clients

  def test_app_syntax
    new_session do |ossi|
      ossi.logs_in_with({ :username => people(:test).username, :password => "testi",
                          :app_name => clients(:one).name, :app_password => "testi"})
      ossi.puts_app_data(people(:test).guid, clients(:one).id, { :foo => "bar" })
      data = ossi.gets_app_data
      assert_equal data["foo"], "bar"
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
