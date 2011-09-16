class PysmsdConfig < ActiveRecord::Base
   belongs_to :client, :foreign_key => :client_id  
   validates :pysmsd_app_name,:pysmsd_app_password,:pysmsd_host,:pysmsd_port,:presence => true
   validates :pysmsd_enabled,:pysmsd_use_ssl, :inclusion => { :in => [true, false] }
   validates :pysmsd_port, :numericality => {
     :greater_than => 0,
     :less_than => 65536,
     :only_integer => true
   
   }
     

end
