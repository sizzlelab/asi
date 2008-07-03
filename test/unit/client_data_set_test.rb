require 'test_helper'

class ClientDataSetTest < ActiveSupport::TestCase

  def test_create
    set = ClientDataSet.new

    assert ! set.valid?

    set.client = clients(:one)
    
    assert ! set.valid?

    set.person = people(:valid_person)

    assert set.save

    set.put("foo", "bar")
    assert set.save

    40.times do |n|
      set.put("foo", String(n))
    end
    assert set.save

    40.times do |n|
      set.put(String(n), String(n^2))
    end
    assert set.save
  end

  def test_get_and_put
    set = client_data_sets(:one)
    
    set.put("foo", "1")
    set.put("foo", "2")
    
    assert_equal "2", set.get("foo")

    set.put(nil, "foo")
    assert_nil set.get(nil)

    assert_nil set.get("oeusrcoeusrca.rsch")
  end
end
