class CosEvent < ActiveResource::Base
  self.site = RESSI_URL
  self.timeout = RESSI_TIMEOUT
end
