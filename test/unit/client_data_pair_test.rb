require 'test_helper'

class ClientDataPairTest < ActiveSupport::TestCase

  def test_create
    pair = ClientDataPair.new

    assert ! pair.save

    pair.value = "482"
    
    assert ! pair.save
    
    pair.key = "weight"
    
    assert pair.save
    assert_equal ClientDataPair.find_by_id(pair.id), pair
    return pair
  end

  def test_delete
    pair = test_create
    pair.destroy
    assert_nil ClientDataPair.find_by_id(pair.id)
  end

  def test_update
    pair = test_create
    
    pair.key = nil

    assert ! pair.save
    
    assert pair.update_attributes(:key => "foo", :value => "bar")
  end

end
