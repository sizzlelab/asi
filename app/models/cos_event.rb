class CosEvent < ActiveResource::Base
  self.site = APP_CONFIG.ressi_url
  self.timeout = RESSI_TIMEOUT
end
