class ClientDataSet < ActiveRecord::Base
  belongs_to :client
  belongs_to :person
  validates_presence_of :client, :person
  serialize :data, Hash

  def to_json(*a)
    if ! data 
      return {}.to_json(*a)
    end
    data.to_json(*a)
  end

  def data=(d)
    old = read_attribute(:data) || Hash.new
    write_attribute(:data, old.merge(d))
  end
end
