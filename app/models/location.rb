class Location < ActiveRecord::Base
  
  belongs_to :person
  
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
    {
      :latitude => self.latitude,
      :longitude => self.longitude,
      :label => self.label,
      :accuracy => self.accuracy,
      :updated_at => self.updated_at
    }.to_json(*a)
  end

end
