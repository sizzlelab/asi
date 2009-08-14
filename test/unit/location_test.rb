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

require 'test_helper'

class LocationTest < ActiveSupport::TestCase

  def test_create
    loc = Location.new( :person_id => 1,
                  :latitude => 24.852395, 
                  :longitude => -12.1231, 
                  :accuracy => 20,
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
