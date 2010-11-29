if APP_CONFIG.use_hoptoad
  HoptoadNotifier.configure do |config|
    config.api_key = APP_CONFIG.hoptoad_api_key
  end
end