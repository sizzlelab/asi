require 'test_helper'

class BinObjectTest < ActiveSupport::TestCase

  def test_creation_and_delete
    bin_object = BinObject.new( :name => "bin object test 1 name",
                           :data => "bin object test 1 data",
                           :orig_name => "orig_name.txt",
                           :content_type => "text/plain",
                           :poster => people(:test))

    assert bin_object.valid?
    assert bin_object.save
    bin_object_id = bin_object.id
    assert bin_object.delete
    assert_nil BinObject.find_by_id(bin_object_id)
    
    bin_object2 = BinObject.new(:name => "bin object test 2 name",
                           :data => "bin object test 2 data")
    assert !bin_object2.valid?
  end
end
