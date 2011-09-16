require 'test_helper'

class PysmsdConfigTest < ActiveSupport::TestCase
  test "Valid pysmsd port" do
  end
  
  def test_pysmsd_config_validity
    assert pysmsd_configs(:valid_pysmsd_config).valid?
  end
  
  def test_pysmsd_config_invalidity
    assert pysmsd_configs(:invalid_pysmsd_config).invalid?
  end
  
end
