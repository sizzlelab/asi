class ClientDataPair < ActiveRecord::Base
  belongs_to :client_data_set
  validates_presence_of :key
end
