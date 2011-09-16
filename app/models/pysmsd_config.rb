class PysmsdConfig < ActiveRecord::Base
   belongs_to :client, :foreign_key => :client_id  
   validates_presence_of :client_id
   validates_presence_of :pysmsd_app_name,:pysmsd_app_password,:pysmsd_host,:pysmsd_port, :if => :pysmsd_enabled
   validates_presence_of :pysmsd_proxy_host,:pysmsd_proxy_port, :if => :pysmsd_use_proxy
   validates_inclusion_of :pysmsd_enabled,:pysmsd_use_ssl, :in => [true, false] 
   
   validates_numericality_of :pysmsd_port, 
     :greater_than_or_equal_to => 0,
     :less_than => 65536,
     :only_integer => true,
     :if => :pysmsd_enabled
   
    validates_numericality_of :pysmsd_proxy_port, :allow_nil => true,
     :greater_than_or_equal_to => 0,
     :less_than => 65536,
     :only_integer => true,
     :if => :pysmsd_use_proxy
     
end
