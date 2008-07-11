class Location < ActiveRecord::Base
  
  belongs_to :person
  
  validates_numericality_of [:latitude, :longitude, :altitude, 
                             :vertical_accuracy, :horizontal_accuracy]


  validates_each :longitude, :allow_nil  => true do |record, attr, value|
     record.errors.add attr, 'is smaller than -180' if value < -180
     record.errors.add attr, 'is greather than 180' if value > 180
   end
   validates_each :latitude, :allow_nil  => true do |record, attr, value|
     record.errors.add attr, 'is smaller than -90' if value < -90
     record.errors.add attr, 'is greather than 90' if value > 90
   end
                
                             
  
  
  def to_json(*a)
    {
      :latitude => self.latitude,
      :longitude => self.longitude,
      :altitude => self.altitude,
      :label => self.label,
      :vertical_accuracy  => self.vertical_accuracy,
      :horizontal_accuracy => self.horizontal_accuracy,
      :updated_at => self.updated_at
    }.to_json(*a)
  end

end
