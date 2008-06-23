require 'test_helper'

class BinaryItemTest < ActiveSupport::TestCase
  fixtures :binary_items

  def should_create_binary_item
    binary_item = BinaryItems.new
  end

  def test_should_find_binary_item
    id = binary_items(:jpg).id
    assert_nothing_raised { BinaryItem.find(id) }
  end

  def test_should_update_binary_item
    binary_item = binary_items(:jpg)
    data = binary_items(:png).raw_data
    assert binary_item.update_attributes(:data => data, :content_type => "application/foo", :filename => "Foo.bin")

    assert_equal(binary_item.data, binary_items(:png).data)
  end

  def test_should_destroy_binary_item
    binary_item = binary_items(:jpg)
    binary_item.destroy
    assert_raise(ActiveRecord::RecordNotFound) { BinaryItem.find(binary_item.id) }
  end

end
