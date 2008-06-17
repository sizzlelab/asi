require 'test_helper'

class BinaryItemTest < ActiveSupport::TestCase
  fixtures :binary_items

  def should_create_binary_item
    binary_item = BinaryItems.new
  end

  def test_should_find_binary_item
    id = binary_items(:one).id
    assert_nothing_raised { BinaryItem.find(id) }
  end

  def test_should_update_binary_item
    binary_item = binary_items(:one)
    assert binary_item.update_attributes(:data => "CAFEBABE")
  end

  def test_should_destroy_binary_item
    binary_item = binary_items(:one)
    binary_item.destroy
    assert_raise(ActiveRecord::RecordNotFound) { BinaryItem.find(binary_item.id) }
  end

end
