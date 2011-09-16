require 'test_helper'

class PysmsdConfigTest < ActiveSupport::TestCase
  def setup
     
    @valid_pysmsd_config = pysmsd_configs(:valid_pysmsd_config)
    @valid_pysmsd_config_with_proxy = pysmsd_configs(:valid_pysmsd_config_with_proxy)
  end
  
  def test_pysmsd_config_validity
    assert @valid_pysmsd_config.valid?
    assert @valid_pysmsd_config_with_proxy.valid?
  end
  
  def test_pysmsd_config_disabled_validity
    valid_config = pysmsd_configs(:valid_pysmsd_config)
    valid_config.pysmsd_enabled = 0
    valid_config.pysmsd_app_name = nil
    assert valid_config.valid?

    valid_config = pysmsd_configs(:valid_pysmsd_config)
    valid_config.pysmsd_enabled = 0
    valid_config.pysmsd_app_password = nil
    assert valid_config.valid?

    valid_config = pysmsd_configs(:valid_pysmsd_config)
    valid_config.pysmsd_enabled = 0
    valid_config.pysmsd_host = nil
    assert valid_config.valid?

    valid_config = pysmsd_configs(:valid_pysmsd_config)
    valid_config.pysmsd_enabled = 0
    valid_config.pysmsd_port = nil
    assert valid_config.valid?
  end
    
  def test_pysmsd_config_invalidity
    invalid_config = pysmsd_configs(:valid_pysmsd_config)
    invalid_config.pysmsd_app_name = nil
    assert invalid_config.invalid?
    
    invalid_config = pysmsd_configs(:valid_pysmsd_config)
    invalid_config.pysmsd_app_password = nil
    assert invalid_config.invalid?
    
    invalid_config = pysmsd_configs(:valid_pysmsd_config)
    invalid_config.pysmsd_host = nil
    assert invalid_config.invalid?
    
    invalid_config = pysmsd_configs(:valid_pysmsd_config)
    invalid_config.pysmsd_port = nil
    assert invalid_config.invalid?
    
    invalid_config = pysmsd_configs(:valid_pysmsd_config)
    invalid_config.pysmsd_port = -10
    assert invalid_config.invalid?
  end

  def test_pysmsd_config_proxy_invalidity
    invalid_config = pysmsd_configs(:valid_pysmsd_config_with_proxy)
    invalid_config.pysmsd_proxy_host = nil
    assert invalid_config.invalid?

    invalid_config = pysmsd_configs(:valid_pysmsd_config_with_proxy)
    invalid_config.pysmsd_proxy_port = nil
    assert invalid_config.invalid?

    invalid_config = pysmsd_configs(:valid_pysmsd_config_with_proxy)
    invalid_config.pysmsd_proxy_port = -1010
    assert invalid_config.invalid?
  end
  
end
