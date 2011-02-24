# == Schema Information
#
# Table name: locations
#
#  id         :integer(4)      not null, primary key
#  person_id  :integer(4)
#  latitude   :decimal(15, 12)
#  longitude  :decimal(15, 12)
#  label      :string(255)
#  created_at :datetime
#  updated_at :datetime
#  accuracy   :decimal(15, 3)
#

class Location < ActiveRecord::Base

  belongs_to :person

  attr_protected :created_at, :updated_at

  validates_numericality_of [:latitude, :longitude, :accuracy], :allow_nil => true
  validates_presence_of [:latitude, :longitude], :unless => :no_lat_long?

  validates_each :longitude, :allow_nil  => true do |record, attr, value|
     record.errors.add attr, 'is smaller than -180' if value < -180
     record.errors.add attr, 'is greather than 180' if value > 180
  end

  validates_each :latitude, :allow_nil  => true do |record, attr, value|
   record.errors.add attr, 'is smaller than -90' if value < -90
   record.errors.add attr, 'is greather than 90' if value > 90
  end

  # Return true if both latitude and longitude are missing
  def no_lat_long?
    !self.latitude && !self.longitude
  end

  def to_json(*a)
    location_hash.to_json(*a)
  end

  def location_hash
    {
      :latitude => self.latitude,
      :longitude => self.longitude,
      :label => self.label,
      :accuracy => self.accuracy,
      :updated_at => self.updated_at
    }
  end

end
