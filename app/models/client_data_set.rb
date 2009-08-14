# == Schema Information
#
# Table name: client_data_sets
#
#  id         :integer(4)      not null, primary key
#  client_id  :string(255)
#  person_id  :integer(4)
#  created_at :datetime
#  updated_at :datetime
#  data       :text
#

class ClientDataSet < ActiveRecord::Base
  belongs_to :client
  belongs_to :person
  validates_presence_of :client, :person
  serialize :data, Hash

  attr_protected :created_at, :updated_at

  def to_json(*a)
    if ! data
      return {}.to_json(*a)
    end
    data.to_json(*a)
  end

  # Merges the parameter hash with the current metadata
  def data=(d)
    old = read_attribute(:data) || Hash.new
    write_attribute(:data, old.merge(d))
  end
end
