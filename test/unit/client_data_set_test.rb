require 'test_helper'

class ClientDataSetTest < ActiveSupport::TestCase

  def test_create
    set = ClientDataSet.new

    assert ! set.valid?

    set.client = clients(:one)
    
    assert ! set.valid?

    set.person = people(:valid_person)

    assert set.save

    set["foo"] = "bar"
    assert set.save

    40.times do |n|
      set["foo"] = String(n)
    end
    assert set.save

    40.times do |n|
      set[String(n)] = String(n^2)
    end
    assert set.save
  end

  def test_get_and_put
    set = client_data_sets(:one)
    
    set["foo"] = "1"
    set["foo"] = "2"
    
    assert_equal "2", set["foo"]

    assert_nil set["oeusrcoeusrca.rsch"]
  end

  def test_set
    set = ClientDataSet.new
    set.data = { :foo => "bar", :bar => "foo" }
    assert_equal "foo", set.data[:bar]
    assert_equal "bar", set.data[:foo]
  end
    
end
