class CollectionMetadataPair < ActiveRecord::Base
  belongs_to :collection
  validates_presence_of :key
end
