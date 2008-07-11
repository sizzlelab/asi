class ClientDataSet < ActiveRecord::Base
  belongs_to :client
  belongs_to :person
  validates_presence_of :client, :person

  def get(key)
    pair = get_pair(key)
    if ! pair
      return nil
    end
    return pair.value
  end
  
  def put(key, value)
    pair = get_pair(key) || ClientDataPair.new(:key => key, :value => value, :client_data_set_id => id)
    pair.value = value
    pair.save
  end

  def to_json(*a)
    hash = {}
    pairs = ClientDataPair.find(:all, :conditions => { :client_data_set_id => id })
    pairs.each { |item| hash[item.key] = item.value }
    return hash.to_json(*a)
  end

  private
  
  def get_pair(key)
    ClientDataPair.find_by_key(key, :conditions => { :client_data_set_id => id })
  end    
end
