class CosEvent < ActiveResource::Base
  self.site = APP_CONFIG.ressi_url
  self.timeout = Asi::Application.config.RESSI_TIMEOUT
end
