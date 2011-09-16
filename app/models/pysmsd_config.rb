class PysmsdConfig < ActiveRecord::Base
   belongs_to :client, :foreign_key => :client_id  
   validates_presence_of :client_id
   validates_presence_of :app_name,:app_password,:host,:port, :if => :enabled
   validates_presence_of :proxy_host,:proxy_port, :if => :use_proxy
   validates_inclusion_of :enabled,:use_ssl, :in => [true, false] 
   
   validates_numericality_of :port, 
     :greater_than_or_equal_to => 0,
     :less_than => 65536,
     :only_integer => true,
     :if => :enabled
   
    validates_numericality_of :proxy_port, :allow_nil => true,
     :greater_than_or_equal_to => 0,
     :less_than => 65536,
     :only_integer => true,
     :if => :use_proxy
     
end
