require 'test_helper'

class LocationTest < ActiveSupport::TestCase

  def test_create
    loc = Location.new( :person_id => 1,
                  :latitude => 24.852395, 
                  :longitude => -12.1231, 
                  :altitude => 432,
                  :horizontal_accuracy => 12,
                  :vertical_accuracy => 49,
                  :label => "Experimental grounds \\o/"
                  )
    assert loc.valid?
    assert loc.save
  end
  
  def test_coordinate_limits
    loc = Location.new( :person_id => 1,
                  :latitude => 124.852395
                  )
    assert ! loc.valid?
    loc = Location.new( :person_id => 1,
                  :longitude => -184.852395
                  )
    assert ! loc.valid?
  end
end
