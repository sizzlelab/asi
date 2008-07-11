class ClientDataPair < ActiveRecord::Base
  belongs_to :client_data_set
  validates_presence_of :key

  def to_json(*a)
    { key => value }.to_json
  end
end
